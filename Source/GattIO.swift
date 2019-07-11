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

public enum GattError: Error {
    case serviceNotFound
    case characteristicNotFound
    case notConnected
}

/// Reactive interface into the underlying platform-level peripheral Bluetooth GATT operators.
public protocol GattIO {
    /// The connection state of the peripheral backing this GattIO.
    var isConnected: Observable<Bool> { get }
    
    var deviceName: String? { get }
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
    
    func registerForNotification(service: CBUUID, characteristic: CBUUID, preprocessor: Preprocessor?) -> Completable
    func notificationData(for characteristic: CBUUID) -> Observable<Data>
}

/// Aggregates Data for the purpose of demarcation.
public protocol Preprocessor {
    /// Process the raw bytes and aggregate into a demarcated packet.
    /// - parameter data: the raw data.
    /// - returns: Optional of the aggregated, processed data, or else nil if the
    ///     aggregated data does not yet represent a complete demarcated packet.
    func process(data: Data) -> Data?
}

public extension ObservableType where E == GattIO {
    /// Convenience function to provide a one-off read operation without queueing capabilities. Not recommended, but succient.
    func read(service: CBUUID, characteristic: CBUUID) -> Observable<Data?> {
        return flatMap { (element: E) -> Single<Data?> in
            element.read(service: service, characteristic: characteristic)
        }
    }
    
    /// Convenience function to provide a one-off write operation without queueing capabilities. Not recommended, but succient.
    func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        return flatMap { (element: E) -> Completable in
            element.write(service: service, characteristic: characteristic, data: data)
            }.asCompletable()
    }
}
