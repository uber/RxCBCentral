/*
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

public protocol ConnectionManagerType: class {
    /// Scan for peripherals with specified services. Note that only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create a ScanMatching object to provide custom filtering logic for peripherals you scan for
    /// Uses the `defaultScanTimeout`
    /// Returns: A sequence of `CBPeripherals` that we've found while scanning that match the requested services and `scanMatcher` filtering
    func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?) -> Observable<CBPeripheral>
    
    /// Scan for peripherals with specified services. Note that only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create a ScanMatching object to provide custom filtering logic for peripherals you scan for
    /// Uses the `scanTimeout` provided
    /// Returns: A sequence of `CBPeripherals` that we've found while scanning that match the requested services and `scanMatcher` filtering
    func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, scanTimeout: RxTimeInterval) -> Observable<CBPeripheral>
    
    /// Aborts the current scan for this `ConnectionManagerType`, if one is taking place.
    func stopScan()
    
    /// Convenience function to scan and connect to a peripheral with specified services.
    /// Note: only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create your own ScanMatching object to provide custom logic for selecting a peripheral to connect to (ex: device name)
    /// Uses `defaultScanTimeout` and `defaultConnectionTimeout` for scan and connection attempts.
    func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?) -> Observable<GattIO>
    
    /// Convenience function to scan and connect to a peripheral with specified services.
    /// Note: only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create your own ScanMatching object to provide custom logic for selecting a peripheral to connect to (ex: device name)
    func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, scanTimeout: RxTimeInterval, connectionTimeout: RxTimeInterval) -> Observable<GattIO>
    
    // TODO: add functionality to disconnect from a specific peripheral, since multiple connections are supported.
    /// Cancels an active or pending connection to <i>peripheral</i>. Note that this is non-blocking, and any `CBPeripheral`
    /// commands that are still pending to <i>peripheral</i> may or may not complete. See {@link cancelPeripheralConnection} for more details.
    func disconnectPeripheral()
}

// State of the ConnectionManager.
public enum ConnectionManagerState {
    case connected
    case connecting
    case disconnected(Swift.Error?)
    case scanning
}

public typealias ScanData = (peripheral: CBPeripheral, advertisementData: [String: Any], RSSI: NSNumber)

extension ConnectionManagerState: Equatable {
    public static func == (lhs: ConnectionManagerState, rhs: ConnectionManagerState) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected):
            return true
        case (.connecting, .connecting):
            return true
        case (.scanning, .scanning):
            return true
        case (.disconnected(_), .disconnected(_)):
            return true
        default:
            return false
        }
    }
}

public struct ConnectionConstants {
    /// Number of seconds to scan before throwing a ConnectionManagerError.scanTimeout error
    public static let defaultScanTimeout: RxTimeInterval = 30
    
    /// Number of seconds to attempt Bluetooth connection with a discovered peripheral
    /// before throwing a ConnectionManagerError.connectionTimeout error
    public static let defaultConnectionTimeout: RxTimeInterval = 45
}

public enum ConnectionManagerError: Error {
    case alreadyScanning
    case scanTimeout
    case connectionTimeout
}
