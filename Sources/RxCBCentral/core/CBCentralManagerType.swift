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

protocol CBCentralManagerType: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var isScanning: Bool { get }
    var state: CBManagerState { get }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    
    func connect(_ peripheral: CBPeripheralType, options: ConnectionManagerOptions?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType)
}

extension CBCentralManager: CBCentralManagerType {
    func connect(_ peripheral: CBPeripheralType, options: ConnectionManagerOptions?) {
        if let peripheral = peripheral as? CBPeripheral {
            RxCBLogger.sharedInstance.log("Connecting to: \(peripheral.description)")
            connect(peripheral, options: options?.asDictionary)
        }
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        if let peripheral = peripheral as? CBPeripheral {
            cancelPeripheralConnection(peripheral)
        }
    }
}
