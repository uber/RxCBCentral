/*
 *  Copyright (c) 2019 Uber Technologies, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CoreBluetooth
import Foundation
import RxSwift

public struct ConnectionManagerOptions {
    let notifyOnConnection: Bool
    let notifyOnDisconnection: Bool
    
    /// A String containing a unique identifier (UID) for the `CBCentralManager` that is being instantiated. This UID is used
    /// by the system to identify a specific `CBCentralManager` instance for restoration and, therefore, must remain the same for
    /// subsequent application executions in order for the manager to be restored.
    let restoreIdentifier: String?
    
    public init(notifyOnConnection: Bool, notifyOnDisconnection: Bool, restoreIdentifier: String?) {
        self.notifyOnConnection = notifyOnConnection
        self.notifyOnDisconnection = notifyOnDisconnection
        self.restoreIdentifier = restoreIdentifier
    }
    
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [:]
        
        dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
        dict[CBConnectPeripheralOptionNotifyOnConnectionKey] = NSNumber(booleanLiteral: notifyOnConnection)
        dict[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = NSNumber(booleanLiteral: notifyOnDisconnection)
        
        return dict
    }
}

public class ConnectionManager: NSObject, ConnectionManagerType, CBCentralManagerDelegate {
    
    public init(bluetoothDetector: BluetoothDetectorType, queue: DispatchQueue? = nil, options: ConnectionManagerOptions? = nil) {
        self.bluetoothDetector = bluetoothDetector
        self.dispatchQueue = queue
        self.options = options
        
        centralManager = CBCentralManager(delegate: nil, queue: dispatchQueue, options: options?.asDictionary)
        super.init()
    
        centralManager.delegate = self
    }
    
    public var isScanning: Bool {
        return centralManager.isScanning
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?) -> Observable<CBPeripheral> {
        return scan(for: services, scanMatcher: scanMatcher, scanTimeout: ConnectionConstants.defaultScanTimeout)
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?,
                     scanTimeout: RxTimeInterval) -> Observable<CBPeripheral> {
        // check that bluetooth is powered on
        guard centralManager.state == .poweredOn else {
            if centralManager.state == .poweredOff || centralManager.state == .resetting {
                RxCBLogger.sharedInstance.log("Error: bluetooth disabled")
                return Observable.error(BluetoothError.disabled)
            } else {
                RxCBLogger.sharedInstance.log("Error: bluetooth unsupported")
                return Observable.error(BluetoothError.unsupported)
            }
        }
        
        guard !isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
        
        return generateMatchingPeripheralSequence(with: scanMatcher)
            .timeout(scanTimeout, other: Observable.error(ConnectionManagerError.scanTimeout), scheduler: MainScheduler.instance)
            .do(onError: { _ in
                self.centralManager.stopScan()
            }, onSubscribe: {
                self.centralManager.scanForPeripherals(withServices: services, options: self.options?.asDictionary)
            }, onDispose: {
                self.centralManager.stopScan()
            })
    }
    
    public func stopScan() {
        centralManager.stopScan()
    }
    
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?) -> Observable<GattIO> {
        return connectToPeripheral(with: services, scanMatcher: scanMatcher, scanTimeout: ConnectionConstants.defaultScanTimeout, connectionTimeout: ConnectionConstants.defaultConnectionTimeout)
    }
    
    public func connectToPeripheral(with services: [CBUUID]?,
                                    scanMatcher: ScanMatching?,
                                    scanTimeout: RxTimeInterval,
                                    connectionTimeout: RxTimeInterval) -> Observable<GattIO> {
        // check that bluetooth is powered on
        guard centralManager.state == .poweredOn else {
            if centralManager.state == .poweredOff || centralManager.state == .resetting {
                RxCBLogger.sharedInstance.log("Error: bluetooth disabled")
                return Observable.error(BluetoothError.disabled)
            } else {
                RxCBLogger.sharedInstance.log("Error: bluetooth unsupported")
                return Observable.error(BluetoothError.unsupported)
            }
        }
        
        guard !isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
        
        let peripheralObservable = generateMatchingPeripheralSequence(with: scanMatcher)
        
        let sharedGattIOObservable =
            generateGattIOSequence(with: peripheralObservable, connectionTimeout: connectionTimeout)
            .do(onSubscribe: {
                RxCBLogger.sharedInstance.log("Scanning...")
                self.centralManager.scanForPeripherals(withServices: services, options: self.options?.asDictionary)
            })
            .timeout(scanTimeout, other: Observable.error(ConnectionManagerError.scanTimeout), scheduler: MainScheduler.instance)
            .do(onError: { error in
                self.centralManager.stopScan()
                RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
            })
    
        return sharedGattIOObservable
    }
    
    public func disconnectPeripheral() {
        guard let peripheral = peripheral, centralManager.state == .poweredOn else  { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // CoreBluetoothDetector handles these state changes
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let scanData = (peripheral, advertisementData, RSSI)
        didDiscoverPeripheralSubject.onNext(scanData)
        self.discoveredPeripherals.insert(peripheral)
        RxCBLogger.sharedInstance.log("Discovered peripheral: \(peripheral.description), RSSI: \(RSSI)")
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectToPeripheralSubject.onNext(peripheral)
        didUpdateStateSubject.onNext(.connected)
        RxCBLogger.sharedInstance.log("Connected to: \(peripheral.description)")
        self.peripheral = peripheral
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(error))
        RxCBLogger.sharedInstance.log("Disconnected from: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
        self.peripheral = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(error))
        RxCBLogger.sharedInstance.log("Failed to connect: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
    }
    
    // MARK: - Private
    
    private let centralManager: CBCentralManager
    private var peripheral: CBPeripheral?
    private var discoveredPeripherals: Set<CBPeripheral> = []

    private let bluetoothDetector: BluetoothDetectorType
    private let dispatchQueue: DispatchQueue?
    private let options: ConnectionManagerOptions?
    
    private let didDiscoverPeripheralSubject: PublishSubject<ScanData> = PublishSubject()
    private let didConnectToPeripheralSubject: PublishSubject<CBPeripheral> = PublishSubject()
    private let didUpdateStateSubject = BehaviorSubject<ConnectionManagerState>(value: ConnectionManagerState.disconnected(nil))
    
    private func connect(_ peripheral: CBPeripheral, options: ConnectionManagerOptions? = nil) {
        centralManager.connect(peripheral, options: options?.asDictionary)
        didUpdateStateSubject.onNext(.connecting)
    }
    
    private func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: ConnectionManagerOptions? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options?.asDictionary)
        didUpdateStateSubject.onNext(.scanning)
    }
    
    private func generateMatchingPeripheralSequence(with scanMatcher: ScanMatching?) -> Observable<CBPeripheral> {
        // if no scanMatcher provided, return the first peripheral discovered that meets our serviceUUID requirements
        guard let scanMatcher = scanMatcher else {
            return didDiscoverPeripheralSubject.map { $0.peripheral }
        }
        
        // use the provided scanMatcher to determine which peripherals to discover
        return didDiscoverPeripheralSubject
            .flatMapLatest { (scanData: ScanData) -> Observable<CBPeripheral> in
                return scanMatcher.accept(scanData)
            }
    }
    
    private func generateGattIOSequence(with matchingPeripheralSequence: Observable<CBPeripheral>, connectionTimeout: RxTimeInterval) -> Observable<GattIO> {
        
        return matchingPeripheralSequence
            .take(1)
            .do(onNext: { (peripheral: CBPeripheral) in
                self.centralManager.stopScan()
                self.centralManager.connect(peripheral, options: self.options?.asDictionary)
                self.didUpdateStateSubject.onNext(.connecting)
            })
            .timeout(connectionTimeout, other: Observable.error(ConnectionManagerError.connectionTimeout), scheduler: MainScheduler.instance)
            .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<CBPeripheral> in
                return self.didConnectToPeripheralSubject.asObservable()
            })
            .take(1)
            .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<GattIO> in
                self.didUpdateStateSubject.onNext(.connected)
                let gattIO: GattIO = CoreGattIO(peripheral: peripheral, connectionState: self.didUpdateStateSubject.asObservable())
                return Observable.just(gattIO)
            })
    }
}

extension ConnectionManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyScanning:
            return NSLocalizedString("Central is already scanning.", comment: "Connection manager error")
        case .scanTimeout:
            return NSLocalizedString("Scanning for peripheral timed out.", comment: "Connection manager error")
        case .connectionTimeout:
            return NSLocalizedString("Connectiing to peripheral timed out.", comment: "Connection manager error")
        }
    }
}

