
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

public struct ScanOptions {
    /// A Bool indicating that the scan should run without duplicate filtering. By default, multiple discoveries of the
    /// same peripheral are coalesced into a single discovery event. Specifying this option will cause a discovery event to be generated
    /// every time the peripheral is seen, which may be many times per second. This can be useful in specific situations, such as making
    /// a connection based on a peripheral's RSSI, but may have an adverse affect on battery-life and application performance.
    public let allowDuplicates: Bool

    /// An Array of `CBUUID` objects respresenting service UUIDs. Causes the scan to also look for peripherals soliciting
    /// any of the services contained in the list.
    public let solicitedServiceUUIDs: [CBUUID]?

    public init(allowDuplicates: Bool = false, solicitedServiceUUIDs: [CBUUID]? = nil) {
        self.allowDuplicates = allowDuplicates
        self.solicitedServiceUUIDs = solicitedServiceUUIDs
    }

    init(_ dict: [String: Any]) {
        self.init(allowDuplicates: (dict[CBCentralManagerScanOptionAllowDuplicatesKey] as? NSNumber)?.boolValue ?? false,
                  solicitedServiceUUIDs: dict[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID])
    }

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [:]
        
        dict[CBCentralManagerScanOptionAllowDuplicatesKey] = NSNumber(booleanLiteral: allowDuplicates)
        
        if let solicitedServiceUUIDs = solicitedServiceUUIDs {
            dict[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = solicitedServiceUUIDs
        }
        
        return dict
    }
}
