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

public protocol ConnectionManagerType: class {
    func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, scanTimeout: RxTimeInterval, connectionTimeout: RxTimeInterval) -> Observable<GattIO>
    func disconnectPeripheral()
}

// State of the ConnectionManager.
public enum ConnectionManagerState {
    case connected
    case connecting
    case disconnected(Swift.Error?)
    case scanning
}

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
    // seconds
    public static let defaultScanTimeout: RxTimeInterval = 30
    // seconds
    public static let defaultConnectionTimeout: RxTimeInterval = 45
}

enum ConnectionManagerError: Error {
    case alreadyScanning
    case scanTimeout
    case connectionTimeout
}
