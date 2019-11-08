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

/// Provides a protocol to collect discovered scan data, including peripherals, and emit matches.
/// This is used for the `CollectionManagerType`'s convenience functions to allow consumers
/// to scan and connect to a specific peripheral in very few lines of code.
public protocol ScanMatching {
    /// Pass `ScanData` into this object to determine if the discovered data matches what you are looking for.
    /// Build your own `ScanMatching` implementation to accept `ScanData` and emit into `match`.
    func accept(_ scanData: ScanData)
    
    /// A sequence of `ScanData`, including a peripheral, that matches the requirements of our `ScanMatching` implementation.
    /// - important: `ConnectionManagerType.connectToPeripheral(services:scanMatcher:)` uses the first emission of `match` by default to initiation peripheral connection.
    var match: Observable<ScanData> { get }
}
