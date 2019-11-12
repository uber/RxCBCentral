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

/// Responsible for queueing, listening for notifications,  and handling GattOperations using the underlying RxPeripheral for BLE communication.
public protocol RxPeripheralManagerType: class {
    /// The peripheral we communicate with using this manager.
    /// May be set multiple times as connection cycles occur.
    var rxPeripheral: RxPeripheral? { get set }
    
    /// The connection state of the `rxPeripheral`  peripheral.
    /// Emits whenever the connection status changes.
    var isConnected: Observable<Bool> { get }
    
    /// A function to queue GATT operations (BLE reads, writes, etc.)
    /// - parameter operation: the BLE request to send to the `rxPeripheral`
    /// - returns: a `Single` containing the type that corresponds to the type of operation that was queued.
    func queue<O: GattOperation>(operation: O) -> Single<O.Element>
    
    /// Register to receive notifications from the `rxPeripheral` for a particular `characteristic` channel.
    /// This allows the peripheral to send updates periodically without the central needing to poll for new data.
    /// - parameter characteristic: the `CBUUID` for the characteristic you want to subscribe to to receive notifications.
    /// - returns: the `Data` for the`rxPeripheral` notification for the given `characteristic` CBUUID.
    func receiveNotifications(for characteristic: CBUUID) -> Observable<Data>
}

