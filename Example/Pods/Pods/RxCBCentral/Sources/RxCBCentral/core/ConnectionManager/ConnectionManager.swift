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

public class ConnectionManager: NSObject, ConnectionManagerType, CBCentralManagerDelegate {
    
    public init(rxPeripheralManager: RxPeripheralManagerType, queue: DispatchQueue? = nil, options: ConnectionManagerOptions? = nil) {
        self.rxPeripheralManager = rxPeripheralManager
        self.options = options
        centralManager = CBCentralManager(delegate: nil, queue: queue, options: options?.asDictionary)
        super.init()
        centralManager.delegate = self
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?,
                     options: ScanOptions?) -> Observable<ScanData> {
        return scan(for: services, scanMatcher: scanMatcher, options: options, scanTimeout: ScanDefaults.defaultScanTimeout)
    }
    
    public func scan(for services: [CBUUID]?,
                     scanMatcher: ScanMatching?,
                     options: ScanOptions?,
                     scanTimeout: RxTimeInterval) -> Observable<ScanData> {

        // CBCentralManager's initial bluetooth state is always `.unsupported` after init.
        // Filter + timeout gives the ConnectionManager's CBCentralManager instance time to spin up and determine
        // actual BLE state, enabling proper behavior when BLE is on and this class is lazily instantiated.
        return bluetoothEnabledSubject
            .filter { $0 } // wait for bluetooth state to be enabled before performing BLE operations
            .take(1)
            .timeout(bluetoothEnabledTimeout, other: Observable.error(ConnectionManagerError.bluetoothDisabled), scheduler: MainScheduler.instance)
            .flatMapLatest { _ -> Observable<Bool> in
                return self.bluetoothEnabledSubject
            }
            .flatMap { (isBluetoothEnabled: Bool) -> Observable<ScanData> in
                // return error if BLE is disabled mid-scan
                guard isBluetoothEnabled else { return Observable.error(BluetoothError.disabled) }
                guard !self.centralManager.isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
                
                // scan for peripherals
                self.scanForPeripherals(withServices: services, options: options)
                
                // return filtered peripheral sequence that matches requirements
                return self.generateMatchingPeripheralSequence(with: scanMatcher)
            }
            .timeout(scanTimeout, other: Observable.error(ConnectionManagerError.scanTimeout), scheduler: MainScheduler.instance)
            .do(onError: { error in
                if let error = error as? ConnectionManagerError {
                    switch error {
                    case .alreadyScanning, .scanTimeout, .bluetoothDisabled:
                        self.didUpdateStateSubject.onNext(.disconnected(error))
                    case .connectionFailed, .connectionTimeout: break
                    }
                }
     
                self.stopScan()
            }, onDispose: {
                self.stopScan()
            })
    }
    
    public func stopScan() {
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
        }
    }
    
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<RxPeripheral> {
        return connectToPeripheral(with: services, scanMatcher: scanMatcher, options: options, scanTimeout: ScanDefaults.defaultScanTimeout)
    }
    
    public func connectToPeripheral(with services: [CBUUID]?,
                                    scanMatcher: ScanMatching?,
                                    options: ScanOptions?,
                                    scanTimeout: RxTimeInterval) -> Observable<RxPeripheral> {

        if let sharedRxPeripheralObservable = sharedRxPeripheralObservable {
            return sharedRxPeripheralObservable
        }
        
        let peripheralConnection =
            scan(for: services, scanMatcher: scanMatcher, options: options)
            .take(1)
            .map { (scanData: ScanData) -> CBPeripheralType in
                return scanData.peripheral
            }
            .flatMapLatest { (matchingPeripheral: CBPeripheralType) -> Observable<CBPeripheral> in
                // match found, stop scanning
                self.centralManager.stopScan()
                
                if let peripheral = matchingPeripheral as? CBPeripheral {
                    RxCBLogger.sharedInstance.log("Match found: \(peripheral.description)")
                    
                    // attempt to connect to the first matching peripheral
                    self.connectTo(peripheral: peripheral, options: self.options)
                }
                
                return self.didConnectToPeripheralSubject
            }
            .map { (peripheral: CBPeripheral) -> RxPeripheral in
                // connection successful
                return RxPeripheralImpl(peripheral: peripheral, connectionState: self.didUpdateStateSubject.asObservable())
            }
            .do(onError: { error in
                RxCBLogger.sharedInstance.log("Connection error: \(error.localizedDescription)")
                self.rxPeripheralManager.rxPeripheral = nil
                if let error = error as? ConnectionManagerError {
                    switch error {
                    case .connectionFailed, .connectionTimeout:
                        self.didUpdateStateSubject.onNext(.disconnected(error))
                    case .alreadyScanning, .bluetoothDisabled, .scanTimeout:
                        break
                    }
                }
            }, onDispose: {
                RxCBLogger.sharedInstance.log("Peripheral connection subscription disposed")
                self.sharedRxPeripheralObservable = nil
                self.rxPeripheralManager.rxPeripheral = nil
                self.disconnectPeripheral()
            })
        
        let errorOnDisconnect = didUpdateStateSubject
            .flatMap { (state: ConnectionManagerState) -> Observable<ConnectionManagerState> in
                if case .disconnected(let error?) = state {
                    // propogate an error on the Rx chain if we unexpectedly disconnect or connection fails
                    return Observable.error(error)
                }
                return Observable.of(state)
            }
        
        sharedRxPeripheralObservable = Observable.combineLatest(peripheralConnection, errorOnDisconnect)
            .map { (peripheral: RxPeripheral, _) -> RxPeripheral in
                return peripheral
            }
            .share(replay: 1)
        
        return sharedRxPeripheralObservable ?? Observable.never()
    }
    
    private func disconnectPeripheral() {
        guard let peripheral = peripheral, centralManager.state == .poweredOn else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    public var connectionState: Observable<ConnectionManagerState> {
        return didUpdateStateSubject.asObservable()
            
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
        let advertisements = AdvertisementData(advertisementData)
        let scanData = (peripheralType, advertisements, RSSI)
        didDiscoverPeripheralSubject.onNext(scanData)
        discoveredPeripherals.insert(peripheral)
        RxCBLogger.sharedInstance.log("Discovered peripheral: \(peripheral.description), RSSI: \(RSSI)")
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectToPeripheralSubject.onNext(peripheral)
        didUpdateStateSubject.onNext(.connected(peripheral))
        RxCBLogger.sharedInstance.log("Connected to: \(peripheral.description)")
        self.peripheral = peripheral
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(error != nil ? .connectionFailed : nil))
        RxCBLogger.sharedInstance.log("Disconnected from: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
        self.peripheral = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(.connectionFailed))
        RxCBLogger.sharedInstance.log("Failed to connect: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
    }
    
    // MARK: - Private
    
    private let centralManager: CBCentralManager
    private let rxPeripheralManager: RxPeripheralManagerType
    private var peripheral: CBPeripheral?
    private var discoveredPeripherals: Set<CBPeripheral> = []
    
    private let options: ConnectionManagerOptions?
    
    // small interval to wait for BLE to become enabled to support lazy instantiation of this class
    private let bluetoothEnabledTimeout: RxTimeInterval = .milliseconds(100)
    private let bluetoothEnabledSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    
    private let didDiscoverPeripheralSubject: PublishSubject<ScanData> = PublishSubject()
    private let didConnectToPeripheralSubject: PublishSubject<CBPeripheral> = PublishSubject()

    private let didUpdateStateSubject = BehaviorSubject<ConnectionManagerState>(value: ConnectionManagerState.disconnected(nil))
    
    private var sharedRxPeripheralObservable: Observable<RxPeripheral>?
    
    private func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: ScanOptions? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options?.asDictionary)
        didUpdateStateSubject.onNext(.scanning)
        RxCBLogger.sharedInstance.log("Scanning...")
    }
    
    private func connectTo(peripheral: CBPeripheral, options: ConnectionManagerOptions? = nil) {
        centralManager.connect(peripheral, options: self.options?.asDictionary)
        didUpdateStateSubject.onNext(.connecting(peripheral))
        RxCBLogger.sharedInstance.log("Connecting to: \(peripheral.description)")
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
}

extension ConnectionManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyScanning:
            return NSLocalizedString("Central is already scanning.", comment: "Connection manager error")
        case .bluetoothDisabled:
            return NSLocalizedString("Scanning for peripheral failed, bluetooth is disabled.", comment: "Connection manager error")
        case .scanTimeout:
            return NSLocalizedString("Scanning for peripheral timed out.", comment: "Connection manager error")
        case .connectionTimeout:
            return NSLocalizedString("Connecting to peripheral timed out.", comment: "Connection manager error")
        case .connectionFailed:
            return NSLocalizedString("Disconnected from peripheral with error.", comment: "Connection manager error")
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
