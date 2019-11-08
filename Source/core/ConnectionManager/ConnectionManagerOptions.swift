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

public struct ConnectionManagerOptions {
    /// A `Bool` value that specifies whether the system should display a warning dialog to the user
    /// if Bluetooth is powered off when the central manager is instantiated.
    ///
    /// If the key is not specified, the default value is false.
    ///
    /// - seeAlso: `CBCentralManagerOptionShowPowerAlertKey`
    let showPowerAlert: Bool
    
    /// A `Bool` value that specifies whether the system should display an alert for a given peripheral
    /// if the app is suspended when a successful connection is made.
    ///
    /// - seeAlso: `CBConnectPeripheralOptionNotifyOnConnectionKey`
    let notifyOnConnection: Bool
    
    /// A Boolean value that specifies whether the system should display a disconnection alert for
    /// a given peripheral if the app is suspended at the time of the disconnection.
    ///
    /// - seeAlso: `CBConnectPeripheralOptionNotifyOnDisconnectionKey`
    let notifyOnDisconnection: Bool
    
    /// A String containing a unique identifier (UID) for the `CBCentralManager` that is being instantiated.
    ///
    /// This UID is used by the system to identify a specific `CBCentralManager` instance for restoration
    /// and, therefore, must remain the same for subsequent application executions in order for the
    /// manager to be restored.
    ///
    /// - seeAlso: `CBCentralManagerOptionRestoreIdentifierKey`
    let restoreIdentifier: String?
    
    public init(showPowerAlert: Bool = false, notifyOnConnection: Bool = false, notifyOnDisconnection: Bool = false, restoreIdentifier: String? = nil) {
        self.showPowerAlert = showPowerAlert
        self.notifyOnConnection = notifyOnConnection
        self.notifyOnDisconnection = notifyOnDisconnection
        self.restoreIdentifier = restoreIdentifier
    }
    
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [:]
        dict[CBCentralManagerOptionShowPowerAlertKey] = showPowerAlert
        dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
        dict[CBConnectPeripheralOptionNotifyOnConnectionKey] = NSNumber(booleanLiteral: notifyOnConnection)
        dict[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = NSNumber(booleanLiteral: notifyOnDisconnection)
        return dict
    }
}
