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

import RxSwift

/// An operation to perform against a peripheral. Meant to be queued on a GattManager implementation
/// for serial execution.
public protocol GattOperationExecutable {
    /// Execute the operation. There must be an active subscription to the result stream for the
    /// operation to execute.
    /// - parameter gattIO: the GattIO to execute the operation against.
    func execute(gattIO: GattIO)
}

public protocol GattOperation: GattOperationExecutable {
    associatedtype Element

    var result: Single<Element> { get }
}

public struct GattConstants {
    /// Number of seconds to attempt a GATT operation before throwing a generic Rx timeout error
    public static let defaultOperationTimeout: RxTimeInterval = 30
}
