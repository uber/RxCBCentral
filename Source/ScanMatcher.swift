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

// Provides the capability to specify means to identify discovered peripheral matches.
public protocol ScanMatcher {
    // Pass a peripheral into the ScanMatcher.
    func accept(_ peripheral: CBPeripheral) -> Observable<CBPeripheral>

    // Determines if the ScanData for a discovered peripheral is a match against parameters and logic
    // specified by this ScanMatcher.
//    func findMatchingPeripheral(using scanData: ScanData) -> Observable<CBPeripheral>
}
