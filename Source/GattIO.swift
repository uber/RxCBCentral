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

// Reactive interface into the underlying platform-level peripheral Bluetooth GATT operators.
//
/// @CreateMocks
public protocol GattIO: Preprocessor {
    var isConnected: Bool { get }
    var deviceName: String? { get }
    
    func maxWriteLength(for type: CBCharacteristicWriteType) -> Int
    func readRSSI() -> Single<Int>

    func read(service: CBUUID, characteristic: CBUUID) -> Single<Data?>
    func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable

    func registerForNotification(service: CBUUID, characteristic: CBUUID) -> Completable
}

public protocol Preprocessor {
    func process(data: Data) -> Data
}

public extension ObservableType where E == GattIO {
    func read(service: CBUUID, characteristic: CBUUID) -> Observable<Data?> {
        return flatMap { (element: E) -> Single<Data?> in
            element.read(service: service, characteristic: characteristic)
        }
    }
    
    func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        return flatMap { (element: E) -> Completable in
            element.write(service: service, characteristic: characteristic, data: data)
        }.asCompletable()
    }
}
