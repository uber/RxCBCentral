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

public protocol CBPeripheralType: AnyObject {
    var delegate: CBPeripheralDelegate? { get set }
    
    var name: String? { get }
    var identifier: UUID { get }
    var state: CBPeripheralState { get }
    
    func readRSSI()
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    
    func readValue(for characteristic: CBCharacteristic)
    func writeValue(_ data: Data,
                    for characteristic: CBCharacteristic,
                    type: CBCharacteristicWriteType)
    func setNotifyValue(_ enabled: Bool,
                        for characteristic: CBCharacteristic)
}

/// Wrap CBPeripheral in a protocol to be able to mock it for unit testing
extension CBPeripheral: CBPeripheralType {}


