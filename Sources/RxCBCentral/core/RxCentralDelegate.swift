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
import RxSwift

/// @CreateMock
protocol RxCentralDelegate: CBCentralManagerDelegate, AnyObject {
    var bluetoothCapability: Observable<BluetoothCapability> { get }
    
    var didDiscoverPeripheral: Observable<ScanData> { get }
    var didConnectToPeripheral: Observable<CBPeripheralType> { get }
    var didFailToConnect: Observable<(CBPeripheralType, Error?)> { get }
    var didDisconnectPeripheral: Observable<(CBPeripheralType, Error?)>  { get }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
}

class RxCentralDelegateImpl: NSObject, RxCentralDelegate {
    
    var bluetoothCapability: Observable<BluetoothCapability> {
        return bluetoothCapabilitySubject.asObservable()
    }
    
    var didDiscoverPeripheral: Observable<ScanData> {
        return didDiscoverPeripheralSubject.asObservable()
    }
    
    var didConnectToPeripheral: Observable<CBPeripheralType> {
        return didConnectToPeripheralSubject.asObservable()
    }
    
    var didFailToConnect: Observable<(CBPeripheralType, Error?)> {
        return didFailToConnectSubject.asObservable()
    }
    
    var didDisconnectPeripheral: Observable<(CBPeripheralType, Error?)> {
        return didDisconnectPeripheralSubject.asObservable()
    }
        
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothCapabilitySubject.onNext(.enabled)
            RxCBLogger.sharedInstance.log("Bluetooth powered on.")
            
        case .poweredOff:
            bluetoothCapabilitySubject.onNext(.disabled)
            RxCBLogger.sharedInstance.log("Bluetooth powered off.")
            
        case .resetting:
            bluetoothCapabilitySubject.onNext(.disabled)
            RxCBLogger.sharedInstance.log("Bluetooth resetting.")
            
        case .unauthorized, .unsupported:
            bluetoothCapabilitySubject.onNext(.unsupported)
            RxCBLogger.sharedInstance.log("Bluetooth unauthorized or unsupported.")
            
        case .unknown:
            bluetoothCapabilitySubject.onNext(.unknown)
       
        @unknown default:
            bluetoothCapabilitySubject.onNext(.unknown)
            RxCBLogger.sharedInstance.log("Unknown CBCentralManager state.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let peripheralType: CBPeripheralType = peripheral
        let advertisements = AdvertisementData(advertisementData)
        didDiscoverPeripheralSubject.onNext((peripheralType, advertisements, RSSI))
        RxCBLogger.sharedInstance.log("Discovered peripheral: \(peripheral.description), RSSI: \(RSSI)")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        didConnectToPeripheralSubject.onNext(peripheral)
        RxCBLogger.sharedInstance.log("Connected to: \(peripheral.description)")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        didFailToConnectSubject.onNext((peripheral, error))
        RxCBLogger.sharedInstance.log("Failed to connect: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        didDisconnectPeripheralSubject.onNext((peripheral, error))
        RxCBLogger.sharedInstance.log("Disconnected from: \(peripheral.description)\nError: \(error?.localizedDescription ?? "none")")
    }
    
    // MARK: - Private
    
    private let bluetoothCapabilitySubject = ReplaySubject<BluetoothCapability>.create(bufferSize: 1)
    
    private let didDiscoverPeripheralSubject = PublishSubject<ScanData>()
    private let didConnectToPeripheralSubject = PublishSubject<CBPeripheralType>()
    private let didFailToConnectSubject = PublishSubject<(CBPeripheralType, Error?)>()
    private let didDisconnectPeripheralSubject = PublishSubject<(CBPeripheralType, Error?)>()
}
