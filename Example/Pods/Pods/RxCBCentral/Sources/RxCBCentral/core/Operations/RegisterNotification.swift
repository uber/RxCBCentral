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

/// Register for characteristic notifications.
public class RegisterNotification: GattOperation {
    
    public let result: Single<()>
    
    public convenience init(service: CBUUID, characteristic: CBUUID) {
        self.init(service: service, characteristic: characteristic, timeoutSeconds: GattConstants.defaultOperationTimeout, preprocessor: nil)
    }
    
    public init(service: CBUUID, characteristic: CBUUID, timeoutSeconds: RxTimeInterval = GattConstants.defaultOperationTimeout, preprocessor: Preprocessor? = nil, scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .utility)) {
        let _peripheralSubject: BehaviorSubject<RxPeripheral?> = BehaviorSubject(value: nil)
        self._peripheralSubject = _peripheralSubject
        
        result = _peripheralSubject
            .filterNil()
            .take(1)
            .asSingle()
            .do(onSuccess: { _ in
                _peripheralSubject.onNext(nil)
            })
            .flatMap { (rxPeripheral: RxPeripheral) -> Single<()> in
                rxPeripheral.registerForNotification(service: service, characteristic: characteristic, preprocessor: preprocessor)
                    .andThen(Single.just(()))
            }
            .asObservable()
            .share()
            .take(1)
            .asSingle()
            .timeout(timeoutSeconds, scheduler: scheduler)
    }
    
    public func execute(with peripheral: RxPeripheral) {
        _peripheralSubject.onNext(peripheral)
    }
    
    private let _peripheralSubject: BehaviorSubject<RxPeripheral?>
}
