
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
import RxSwift

/// Register for characteristic notifications.
public class RegisterNotification: GattOperation {

    public let result: Single<()>
    
    public init(service: CBUUID, characteristic: CBUUID, timeoutSeconds: RxTimeInterval, preprocessor: Preprocessor? = nil, scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .utility)) {
        let gattSubject: BehaviorSubject<GattIO?> = BehaviorSubject(value: nil)
        self._gattSubject = gattSubject
        
        result = _gattSubject
            .filterNil()
            .take(1)
            .asSingle()
            .do(onSuccess: { gattIO in
                gattSubject.onNext(nil)
            })
            .flatMap { (gattIO: GattIO) -> Single<()> in
                gattIO.registerForNotification(service: service, characteristic: characteristic, preprocessor: preprocessor)
                    .andThen(Single.just(()))
            }
            .asObservable()
            .share()
            .take(1)
            .asSingle()
            .timeout(timeoutSeconds, scheduler: scheduler)
    }
    
    public func execute(gattIO: GattIO) {
        _gattSubject.onNext(gattIO)
    }
    
    private let _gattSubject: BehaviorSubject<GattIO?>
}
