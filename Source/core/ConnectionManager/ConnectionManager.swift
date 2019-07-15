//
//  Copyright (c) 2019 Uber Technologies, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreBluetooth
import Foundation
import RxSwift

open class ConnectionManager: NSObject, ConnectionManagerType, CBCentralManagerDelegate {
    
    public init(queue: DispatchQueue? = nil, options: ConnectionManagerOptions? = nil) {
        self.options = options
        centralManager = CBCentralManager(delegate: nil, queue: queue, options: options?.asDictionary)
        super.init()
        
        centralManager.delegate = self
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?) -> Observable<ScanData> {
        return scan(for: services, scanMatcher: scanMatcher, scanTimeout: ConnectionConstants.defaultScanTimeout)
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?,
                     scanTimeout: RxTimeInterval) -> Observable<ScanData> {
        
        guard !centralManager.isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
        
        // wait for bluetooth state to be enabled before performing BLE operations
        return bluetoothEnabledSubject
            .filter { $0 }
            .flatMapLatest { _ -> Observable<ScanData> in
                return self.generateMatchingPeripheralSequence(with: scanMatcher)
            }
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
        
        guard !centralManager.isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
        
        let peripheralObservable = generateMatchingPeripheralSequence(with: scanMatcher)
            .map { (scanData: ScanData) -> CBPeripheralType in
                return scanData.peripheral
        }
        
        // wait for bluetooth state to be enabled before performing BLE operations
        return bluetoothEnabledSubject
            .filter { $0 }
            .flatMapLatest { _ -> Observable<GattIO> in
                return self.connectToPeripheral(with: peripheralObservable, connectionTimeout: connectionTimeout)
            }
            .do(onSubscribe: {
                RxCBLogger.sharedInstance.log("Scanning...")
                self.centralManager.scanForPeripherals(withServices: services, options: self.options?.asDictionary)
            })
            .timeout(scanTimeout, other: Observable.error(ConnectionManagerError.scanTimeout), scheduler: MainScheduler.instance)
            .do(onError: { error in
                self.centralManager.stopScan()
                RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
            })
    }
    
    public func disconnectPeripheral() {
        guard let peripheral = peripheral, centralManager.state == .poweredOn else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // BluetoothDetector exposes the rest of the states
        switch central.state {
        case .poweredOn:
            bluetoothEnabledSubject.onNext(true)
        default:
            bluetoothEnabledSubject.onNext(false)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let peripheralType: CBPeripheralType = peripheral
        let scanData = (peripheralType, advertisementData, RSSI)
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
    
    private let options: ConnectionManagerOptions?
    
    private let bluetoothEnabledSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    
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
    
    /// Generate a sequence of peripherals and their metadata that we've discovered while scanning
    /// that match the requirements on the given scanMatcher
    private func generateMatchingPeripheralSequence(with scanMatcher: ScanMatching?) -> Observable<ScanData> {
        // if no scanMatcher provided, return the first peripheral discovered that meets our serviceUUID requirements
        guard let scanMatcher = scanMatcher else {
            return didDiscoverPeripheralSubject
        }
        
        // use the provided scanMatcher to determine which peripherals to discover
        return didDiscoverPeripheralSubject
            .do(onNext: { (scanData: ScanData) in
                scanMatcher.accept(scanData)
            })
            .flatMapLatest { (scanData: ScanData) -> Observable<ScanData> in
                return scanMatcher.match
        }
    }
    
    private func connectToPeripheral(with matchingPeripheralSequence: Observable<CBPeripheralType>, connectionTimeout: RxTimeInterval) -> Observable<GattIO> {
        
        return matchingPeripheralSequence
            .take(1)
            .do(onNext: { (peripheral: CBPeripheralType) in
                self.centralManager.stopScan()
                if let peripheral = peripheral as? CBPeripheral {
                    self.centralManager.connect(peripheral, options: self.options?.asDictionary)
                    self.didUpdateStateSubject.onNext(.connecting)
                }
            })
            .timeout(connectionTimeout, other: Observable.error(ConnectionManagerError.connectionTimeout), scheduler: MainScheduler.instance)
            .flatMapLatest { _ -> Observable<CBPeripheral> in
                return self.didConnectToPeripheralSubject.asObservable()
            }
            .take(1)
            .flatMapLatest { (peripheral: CBPeripheral) -> Observable<GattIO> in
                let gattIO: GattIO = CoreGattIO(peripheral: peripheral, connectionState: self.didUpdateStateSubject.asObservable())
                return Observable.just(gattIO)
        }
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
            return NSLocalizedString("Connecting to peripheral timed out.", comment: "Connection manager error")
        }
    }
}

extension ConnectionManagerState: Equatable {
    public static func == (lhs: ConnectionManagerState, rhs: ConnectionManagerState) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected):
            return true
        case (.connecting, .connecting):
            return true
        case (.scanning, .scanning):
            return true
        case (.disconnected(_), .disconnected(_)):
            return true
        default:
            return false
        }
    }
}
