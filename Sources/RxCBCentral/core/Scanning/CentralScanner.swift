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
import Foundation
import RxSwift

public protocol CentralScanner: AnyObject {
    /// Scan for peripherals that have the specified `services`. Provide a `scanMatcher` to filter the `ScanData` returned here.
    ///
    /// - important: Only one scan operation per `CentralScanner` is supported at a time.
    ///
    /// This convenience function uses the `defaultScanTimeout`
    /// Returns: A sequence of `ScanData` that we've found while scanning that matches the requested services and `scanMatcher` filtering
    func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<ScanData>
    
    /// Scan for peripherals with specified services. Note that only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create a ScanMatching object to provide custom filtering logic for peripherals you scan for
    /// Uses the `scanTimeout` provided
    /// Returns: A sequence of `ScanData` that we've found while scanning that matches the requested services and `scanMatcher` filtering
    func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?, scanTimeout: RxTimeInterval) -> Observable<ScanData>
}

public struct ScanOptions {
    /// A `Bool` indicating that the scan should run without duplicate filtering.
    ///
    /// By default, multiple discoveries of the same peripheral are coalesced into a single discovery event.
    /// Specifying this option will cause a discovery event to be generated every time the peripheral is seen,
    /// which may be many times per second. This can be useful in specific situations, such as making a connection
    /// based on a peripheral's RSSI, but may have an adverse affect on battery-life and application performance.
    ///
    /// - seeAlso: `CBCentralManagerOptionRestoreIdentifierKey`
    let allowDuplicates: Bool

    /// An Array of `CBUUID` objects respresenting service UUIDs.
    ///
    /// Causes a scan to also look for peripherals soliciting any of the services contained in the list.
    ///
    /// - seeAlso: `CBCentralManagerScanOptionSolicitedServiceUUIDsKey`
    let solicitedServiceUUIDs: [CBUUID]?

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

public struct ScanDefaults {
    /// Number of seconds to scan before throwing a ConnectionManagerError.scanTimeout error
    public static let defaultScanTimeout: RxTimeInterval = .seconds(20)
}
