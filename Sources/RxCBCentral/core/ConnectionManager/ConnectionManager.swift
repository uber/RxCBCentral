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

public class ConnectionManager: ConnectionManagerType {
    
    init(peripheralGattManager: RxPeripheralManagerType,
         centralManager: CBCentralManagerType,
         delegate: RxCentralDelegate,
         options: ConnectionManagerOptions?) {
        self.peripheralGattManager = peripheralGattManager
        self.centralManager = centralManager
        self.centralDelegate = delegate
        self.options = options
        centralManager.delegate = delegate
    }
    
    public convenience init(peripheralGattManager: RxPeripheralManagerType,
                            queue: DispatchQueue? = nil,
                            options: ConnectionManagerOptions? = nil) {
        
        let delegate = RxCentralDelegateImpl()
        let centralManager = CBCentralManager(delegate: delegate, queue: queue, options: options?.asDictionary)
        
        self.init(peripheralGattManager: peripheralGattManager, centralManager: centralManager, delegate: delegate, options: options)
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
        return centralDelegate
            .bluetoothCapability
            .filter { $0 == .enabled } // wait for bluetooth state to be enabled before performing BLE operations
            .take(1)
            .timeout(bluetoothEnabledTimeout,
                     other: Observable.error(ConnectionManagerError.bluetoothDisabled),
                     scheduler: MainScheduler.instance)
            .flatMapLatest { _ -> Observable<BluetoothCapability> in
                return self.centralDelegate.bluetoothCapability
            }
            .map { capability -> Bool in return capability == .enabled }
            .flatMap { (isBluetoothEnabled: Bool) -> Observable<ScanData> in
                // return error if BLE is disabled mid-scan
                guard isBluetoothEnabled else { return Observable.error(BluetoothError.disabled) }
                guard !self.centralManager.isScanning else { return Observable.error(ConnectionManagerError.alreadyScanning) }
                
                // scan for peripherals
                self.scanForPeripherals(withServices: services, options: options)
                
                // return filtered peripheral sequence that matches requirements
                return self.generateMatchingPeripheralSequence(with: scanMatcher)
            }
            .timeout(scanTimeout,
                     other: Observable.error(ConnectionManagerError.scanTimeout),
                     scheduler: MainScheduler.instance)
            .do(onError: { error in
                if let error = error as? ConnectionManagerError {
                    switch error {
                    case .alreadyScanning, .scanTimeout, .bluetoothDisabled:
                        self.connectionStateSubject.onNext(.disconnected(error))
                    case .connectionFailed, .connectionTimeout: break
                    }
                }
     
                self.stopScan()
            }, onDispose: {
                self.stopScan()
            })
    }
    
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<RxPeripheral> {
        return connectToPeripheral(with: services,
                                   scanMatcher: scanMatcher,
                                   options: options,
                                   scanTimeout: ScanDefaults.defaultScanTimeout)
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
                
                self.connectTo(matchingPeripheral, options: self.options)
                
                return self.centralDelegate.didConnectToPeripheral
            }
            .map { (peripheral: CBPeripheralType) -> RxPeripheral in
                // connection successful
                return RxPeripheralImpl(peripheral: peripheral, connectionState: self.connectionState)
            }
            .do(onError: { error in
                RxCBLogger.sharedInstance.log("Connection error: \(error.localizedDescription)")
                self.peripheralGattManager.rxPeripheral = nil
                if let error = error as? ConnectionManagerError {
                    switch error {
                    case .connectionFailed, .connectionTimeout:
                        self.connectionStateSubject.onNext(.disconnected(error))
                    case .alreadyScanning, .bluetoothDisabled, .scanTimeout:
                        break
                    }
                }
            }, onDispose: {
                RxCBLogger.sharedInstance.log("Peripheral connection subscription disposed")
                self.sharedRxPeripheralObservable = nil
                self.peripheralGattManager.rxPeripheral = nil
                self.disconnectPeripheral()
            })
        
        let errorOnDisconnect =
            connectionStateSubject
            .flatMap { (state: ConnectionState) -> Observable<ConnectionState> in
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
    
    public var connectionState: Observable<ConnectionState> {
        return connectionStateSubject.asObservable()
    }
    
    // MARK: - Private
    
    private let centralManager: CBCentralManagerType
    private let peripheralGattManager: RxPeripheralManagerType
    private let centralDelegate: RxCentralDelegate
    private let options: ConnectionManagerOptions?
    
    private let connectionStateSubject = ReplaySubject<ConnectionState>.create(bufferSize: 1)
    
    private var sharedRxPeripheralObservable: Observable<RxPeripheral>?
    private var peripheral: CBPeripheralType?
        
    // small interval to wait for BLE to become enabled to support lazy instantiation of this class
    private let bluetoothEnabledTimeout: RxTimeInterval = .milliseconds(100)
    
    private func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: ScanOptions? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options?.asDictionary)
        connectionStateSubject.onNext(.scanning)
        RxCBLogger.sharedInstance.log("Scanning for peripherals w/ services: \(serviceUUIDs?.description ?? "none") ")
    }
    
    private func stopScan() {
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
        }
    }
    
    private func connectTo(_ peripheral: CBPeripheralType, options: ConnectionManagerOptions? = nil) {
        centralManager.connect(peripheral, options: self.options)
        connectionStateSubject.onNext(.connecting(peripheral))
    }
    
    /// Generate a sequence of peripherals and their metadata that we've discovered while scanning
    /// that match the requirements on the given scanMatcher
    private func generateMatchingPeripheralSequence(with scanMatcher: ScanMatching?) -> Observable<ScanData> {
        // if no scanMatcher provided, return the first peripheral discovered that meets our serviceUUID requirements
        guard let scanMatcher = scanMatcher else {
            return centralDelegate.didDiscoverPeripheral
        }
        
        // use the provided scanMatcher to determine which peripherals to discover
        return centralDelegate
            .didDiscoverPeripheral
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

extension ConnectionState: Equatable {
    public static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
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
