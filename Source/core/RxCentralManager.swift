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

public class RxCentralManager: NSObject {
    public init(queue: DispatchQueue? = nil, options: CentralManagerOptions? = nil) {
        self.options = options
        
        centralManager = CBCentralManager(delegate: nil, queue: queue, options: options?.asDictionary)
        super.init()
    
        centralManager.delegate = self
    }
    
    // MARK: - Private
    
    private let options: CentralManagerOptions?
    
    private let centralManager: CBCentralManager
    
    private var peripheral: CBPeripheral?
    private var discoveredPeripherals: Set<CBPeripheral> = []

    private let bluetoothCapabilitySubject = ReplaySubject<Capability>.create(bufferSize: 1)
    private let bluetoothEnabledSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    
    private let didDiscoverPeripheralSubject: PublishSubject<ScanData> = PublishSubject()
    private let didConnectToPeripheralSubject: PublishSubject<CBPeripheral> = PublishSubject()
    private let didUpdateStateSubject = BehaviorSubject<ConnectionManagerState>(value: ConnectionManagerState.disconnected(nil))
}

// MARK: - ConnectionManager

extension RxCentralManager: ConnectionManager {
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?) -> Observable<CBPeripheral> {
        return scan(for: services, scanMatcher: scanMatcher, scanTimeout: ConnectionConstants.defaultScanTimeout)
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?,
                     scanTimeout: RxTimeInterval) -> Observable<CBPeripheral> {
    
        guard !centralManager.isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
        
        // check that bluetooth is powered on
        return bluetoothEnabledSubject
            .filter { $0 }
            .flatMapLatest { _ -> Observable<CBPeripheral> in
                // generate a sequence of CBPeripherals that match the given criteria
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
        
        // check that bluetooth is powered on
        return bluetoothEnabledSubject
            .filter { $0 }
            .flatMapLatest { _ -> Observable<GattIO> in
                // take matching CBPeripheral and attempt to connect to it, returning a GattIO reference
                return self.generateGattIOSequence(with: peripheralObservable, connectionTimeout: connectionTimeout)
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
    
    /// TODO: add functionality to disconnect from a specific peripheral, since multiple connections are supported.
    public func disconnectPeripheral() {
        guard let peripheral = peripheral, centralManager.state == .poweredOn else  { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - Private
    
    private func connect(_ peripheral: CBPeripheral, options: CentralManagerOptions? = nil) {
        centralManager.connect(peripheral, options: options?.asDictionary)
        didUpdateStateSubject.onNext(.connecting)
    }
    
    private func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: CentralManagerOptions? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options?.asDictionary)
        didUpdateStateSubject.onNext(.scanning)
    }
    
    private func generateGattIOSequence(with matchingPeripheralSequence: Observable<CBPeripheral>, connectionTimeout: RxTimeInterval) -> Observable<GattIO> {
        
        return matchingPeripheralSequence
            .take(1)
            .do(onNext: { (peripheral: CBPeripheral) in
                self.centralManager.stopScan()
                self.connect(peripheral, options: self.options)
            })
            .timeout(connectionTimeout, other: Observable.error(ConnectionManagerError.connectionTimeout), scheduler: MainScheduler.instance)
            .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<CBPeripheral> in
                return self.didConnectToPeripheralSubject.asObservable()
            })
            .take(1)
            .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<GattIO> in
                let gattIO: GattIO = CoreGattIO(peripheral: peripheral, connectionState: self.didUpdateStateSubject.asObservable())
                return Observable.just(gattIO)
            })
    }
    
    private func generateMatchingPeripheralSequence(with scanMatcher: ScanMatching?) -> Observable<CBPeripheral> {
        // if no scanMatcher provided, return the first peripheral discovered that meets our serviceUUID requirements
        guard let scanMatcher = scanMatcher else {
            return didDiscoverPeripheralSubject.map { $0.peripheral }
        }
        
        // use the provided scanMatcher to determine which peripherals to discover
        return didDiscoverPeripheralSubject
            .do(onNext: { (scanData: ScanData) in
                scanMatcher.accept(scanData)
            })
            .flatMapLatest { _ -> Observable<CBPeripheral> in
                return scanMatcher.matchedPeripheral
        }
    }
}

// MARK: - BluetoothDetector

extension RxCentralManager: BluetoothDetector {
    public var capability: Observable<Capability> {
        return bluetoothCapabilitySubject.asObservable()
    }
    
    public var enabled: Observable<Bool> {
        return bluetoothEnabledSubject.asObservable()
    }
}

// MARK: - CBCentralManagerDelegate

extension RxCentralManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            RxCBLogger.sharedInstance.log("Bluetooth powered off.")
            bluetoothEnabledSubject.onNext(false)
            bluetoothCapabilitySubject.onNext(.disabled)
        case .poweredOn:
            RxCBLogger.sharedInstance.log("Bluetooth powered on.")
            bluetoothEnabledSubject.onNext(true)
            bluetoothCapabilitySubject.onNext(.enabled)
        case .resetting:
            bluetoothEnabledSubject.onNext(false)
            bluetoothCapabilitySubject.onNext(.disabled)
        case .unauthorized:
            bluetoothEnabledSubject.onNext(false)
            bluetoothCapabilitySubject.onNext(.unauthorized)
        case .unknown:
            bluetoothEnabledSubject.onNext(false)
            bluetoothCapabilitySubject.onNext(.unknown)
        case .unsupported:
            bluetoothEnabledSubject.onNext(false)
            bluetoothCapabilitySubject.onNext(.unsupported)
        }
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

