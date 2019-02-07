
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

/// Read data from a GATT characteristic
public struct Read: GattOperation {
    public typealias T = Data?
    public var result: Single<Data?>

    public init(service: CBUUID, characteristic: CBUUID, timeoutSeconds: RxTimeInterval, scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .default)) {
        result =
            _gattSubject
            .take(1)
            .flatMapLatest { gattIO in
                gattIO.read(service: service, characteristic: characteristic)
            }
            .share()
            .asSingle()
            .timeout(timeoutSeconds, scheduler: scheduler)

    }

    public func execute(gattIO: GattIO) {
        _gattSubject.onNext(gattIO)
    }

    private let _gattSubject = ReplaySubject<GattIO>.create(bufferSize: 1)
}
