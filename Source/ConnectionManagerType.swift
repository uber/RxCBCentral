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

/// A protocol that allows you to conveniently scan and connect to a peripheral.
public protocol ConnectionManagerType: CentralScanner {
    /// An Observable that emits the current ConnectionManagerState of the manager
    var connectionState: Observable<ConnectionManagerState> { get }
    
    /// Convenience function to scan and connect to a peripheral with specified services.
    /// Note: only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create your own ScanMatching object to provide custom logic for selecting a peripheral to connect to (ex: device name)
    /// Uses `defaultScanTimeout` and `defaultConnectionTimeout` for scan and connection attempts.
    func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<RxPeripheral>
    
    /// Convenience function to scan and connect to a peripheral with specified services.
    /// Note: only one scan operation per `ConnectionManagerType` is supported at a time.
    /// Create your own ScanMatching object to provide custom logic for selecting a peripheral to connect to (ex: device name)
    func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?, scanTimeout: RxTimeInterval) -> Observable<RxPeripheral>
}

/// State of the ConnectionManager.
public enum ConnectionManagerState {
    case scanning
    case connecting(CBPeripheralType)
    case connected(CBPeripheralType)
    case disconnected(ConnectionManagerError?)
}

public typealias ScanData = (peripheral: CBPeripheralType, advertisementData: AdvertisementData, RSSI: NSNumber)

public struct ConnectionDefaults {
    /// Number of seconds to attempt Bluetooth connection with a discovered peripheral
    /// before throwing a ConnectionManagerError.connectionTimeout error
    public static let defaultConnectionTimeout: RxTimeInterval = 45
}

public enum ConnectionManagerError: Error {
    case bluetoothDisabled
    case alreadyScanning
    case scanTimeout
    case connectionTimeout
    case connectionFailed
}
