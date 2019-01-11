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

import RxSwift

// An operation to perform against a peripheral. Meant to be queued on a GattManager implementation
// for serial execution.

/// @CreateMocks
public protocol GattOperation {
    associatedtype T

    var result: Single<T> { get }
    func execute(gattIO: GattIO)
    func execute(gattIO: GattIO) -> Single<T>
}

extension GattOperation {
    public func execute(gattIO: GattIO) -> Single<T> {
        return result
            .do(onSubscribe: {
                return self.execute(gattIO: gattIO)
            })
    }
}
