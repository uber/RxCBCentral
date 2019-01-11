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


//public enum GattConnectionState {
//    case connecting, connected
//}

// Reactive interface into the underlying platform-level peripheral Bluetooth GATT operators.
//
/// @CreateMocks
public protocol GattIO: Preprocessor {
    var isConnected: Bool { get }
    func maxWriteLength(for type: CBCharacteristicWriteType) -> Int

    func readRSSI() -> Single<Int>

    func read(service: Foundation.UUID, characteristic: Foundation.UUID) -> Single<Data>
    func write(service: Foundation.UUID, characteristic: Foundation.UUID, data: Data) -> Completable

    func registerForNotification(service: Foundation.UUID, characteristic: Foundation.UUID) -> Completable
}

public protocol Preprocessor {
    func process(data: Data) -> Data
}
