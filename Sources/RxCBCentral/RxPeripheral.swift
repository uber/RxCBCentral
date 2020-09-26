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

/// Reactive interface into the underlying platform-level peripheral Bluetooth GATT operators.
public protocol RxPeripheral: AnyObject {
    /// The connection state of the peripheral. Emits wheven connection state changes.
    var isConnected: Observable<Bool> { get }
    
    /// The name of the peripheral.
    var deviceName: String? { get }
    
    /// The max supported write length, in bytes.
    /// Also called MTU (maximum transfer unit).
    var maxWriteLength: Int { get }
    
    /// Read the RSSI (relative signal strength) for the peripheral. Supports reactive Retry
    /// operators. Immediately returns an error if disconnected.
    ///
    /// - returns: Single of the RSSI to the peripheral, or else an error. Expect `GattError` for
    ///     errors that may be retried.
    func readRSSI() -> Single<Int>
    
    /// Perform a GATT read operation upon subscription.
    ///
    /// Supports reactive Retry operators. Immediately returns an error if disconnected.
    ///
    /// - parameter service: the CoreBluetooth UUID of the GATT Service containing the desired Characteristic.
    /// - parameter characteristic: the CoreBluetooth UUID of the GATT Characteristic to read
    /// - returns: Single of the raw Data read from the Characteristic, nil if no data avialable, or else an error. Expect
    ///     `GattError` for errors that may be retried.
    func read(service: CBUUID, characteristic: CBUUID) -> Single<Data?>
    
    /// Perform a GATT write operation upon subscription. Supports reactive Retry operators.
    /// Immediately returns an error if disconnected.
    ///
    /// - parameter service: the CoreBluetooth UUID of the GATT Service containing the desired Characteristic.
    /// - parameter characteristic: the CoreBluetooth UUID of the GATT Characteristic to write to.
    /// - parameter data: raw Data to write to the Characteristic.
    /// - returns: Completable of the operation success, or else an error. Expect `GattError` for
    ///     errors that may be retried.
    func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable
    
    /// Register for GATT notifications for a particular service and characteristic.
    ///
    /// GATT notifications are a mechanism for a peripheral to alert its central that values have changed.
    ///
    /// - parameter service: the CoreBluetooth UUID of the GATT Service containing the desired Characteristic.
    /// - parameter characteristic: the CoreBluetooth UUID of the GATT Characteristic to receive updates about.
    /// - parameter preprocessor: a data aggregator that can perform demarcation. Will process the notification data received
    ///   to return data in the required format.
    ///   Ex: collecting notification data until a complete message is formed, and then performing a COBS decode operation on the data.
    /// - returns: Completable, indicating that we are done registering to receive notification updates for this characteristic.
    /// - note: The preprocessor, if non-nil, will be used only for notifications for the specified `characteristic`.
    /// - seeAlso: [Consistent Overhead Byte Stuffing - COBS](https://en.wikipedia.org/wiki/Consistent_Overhead_Byte_Stuffing)
    func registerForNotification(service: CBUUID, characteristic: CBUUID, preprocessor: Preprocessor?) -> Completable
    
    /// Receive notification data for a specific GATT Characteristic.
    ///
    /// - parameter characteristic: the CoreBluetooth UUID of the GATT Characteristic you want to receive data for.
    /// - returns: A sequence of `Data`.
    ///
    /// - important:
    /// The data returned will be processed by the `Preprocessor` given when registering
    /// for notifications for this `characteristic`, if one was provided.
    func notificationData(for characteristic: CBUUID) -> Observable<Data>
    
    /// Validate if service exist
    func hasService(service: CBUUID) -> Observable<Bool>
    
}

/// Aggregates Data for the purpose of demarcation.
public protocol Preprocessor {
    /// Process the raw bytes and aggregate into a demarcated packet.
    /// - parameter data: the raw data.
    /// - returns: Optional of the aggregated, processed data, or else nil if the
    ///     aggregated data does not yet represent a complete demarcated packet.
    func process(data: Data) -> Data?
}


public enum GattError: Error {
    case serviceNotFound
    case characteristicNotFound
    case notConnected
}
