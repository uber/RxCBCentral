
/**
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
    /// A Bool indicating that the system should, if Bluetooth is powered off when `CBCentralManager` is instantiated, display
    /// a warning dialog to the user.
    let showPowerAlert: Bool

    let notifyOnConnection: Bool
    
    let notifyOnDisconnection: Bool
    
    /// A String containing a unique identifier (UID) for the `CBCentralManager` that is being instantiated. This UID is used
    /// by the system to identify a specific `CBCentralManager` instance for restoration and, therefore, must remain the same for
    /// subsequent application executions in order for the manager to be restored.
    let restoreIdentifier: String?
    
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [:]
        
        dict[CBCentralManagerOptionShowPowerAlertKey] = NSNumber(booleanLiteral: showPowerAlert)
        dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
        dict[CBConnectPeripheralOptionNotifyOnConnectionKey] = NSNumber(booleanLiteral: notifyOnConnection)
        dict[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = NSNumber(booleanLiteral: notifyOnDisconnection)
        
        return dict
    }
}

public class CoreConnectionManager: NSObject, ConnectionManager, CBCentralManagerDelegate {
    public var isScanning: Bool {
        return centralManager.isScanning
    }
    
    public required init(queue: DispatchQueue? = nil, options: ConnectionManagerOptions? = nil) {
        self.dispatchQueue = queue
        self.options = options
        super.init()
    }
    
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatcher?) -> Observable<GattIO> {
        let state = try? didUpdateStateSubject.value()
        let unwrappedState = state ?? .disconnected(ConnectionManagerError.invalidState)
        
        switch unwrappedState {
        case .connected, .connecting, .scanning:
            return Observable.error(ConnectionManagerError.notDisconnected)
        default:
            break
        }
        
        let sharedPeripheralObservable: Observable<CBPeripheral>
        
        if let scanMatcher = scanMatcher {
            sharedPeripheralObservable =
                didDiscoverPeripheralSubject
                    .flatMapLatest { (peripheral: CBPeripheral) -> Observable<CBPeripheral> in
                        return scanMatcher.accept(peripheral)
                    }
        } else {
            sharedPeripheralObservable = didDiscoverPeripheralSubject
        }
        
        let sharedGattIOObservable =
            sharedPeripheralObservable
                .do(onNext: { (peripheral: CBPeripheral) in
                    print(peripheral.name ?? "peripheral discovered")
                    self.centralManager.connect(peripheral, options: self.options?.asDictionary)
                    self.didUpdateStateSubject.onNext(.connecting)
                })
                .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<CBPeripheral> in
                    return self.didConnectToPeripheralSubject.asObservable()
                })
                .take(1)
                .flatMapLatest({ (peripheral: CBPeripheral) -> Observable<GattIO> in
                    let gattIO: GattIO = CoreGattIO(peripheral: peripheral, connectionState: self.didUpdateStateSubject.asObservable())
                    
                    return Observable.just(gattIO)
                })
                .do(onSubscribe: {
                    self.centralManager.scanForPeripherals(withServices: services, options: self.options?.asDictionary)
                })
        
        return sharedGattIOObservable
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // BluetoothDetector handles these state changes
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectToPeripheralSubject.onNext(peripheral)
        didUpdateStateSubject.onNext(.connected)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        didDiscoverPeripheralSubject.onNext(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(error))
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didUpdateStateSubject.onNext(.disconnected(error))
    }
    
    // MARK: - Private
    
    private lazy var centralManager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: dispatchQueue, options: options?.asDictionary)
    }()
    
    private let dispatchQueue: DispatchQueue?
    private let options: ConnectionManagerOptions?
    
    private let didDiscoverPeripheralSubject: PublishSubject<CBPeripheral> = PublishSubject()
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
}
