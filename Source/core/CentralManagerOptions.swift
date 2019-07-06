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

public struct CentralManagerOptions {
    /// A Bool indicating that the system should, if Bluetooth is powered off when `CBCentralManager` is instantiated, display
    /// a warning dialog to the user.
    let showPowerAlert: Bool
    
    /// A Bool indicating that the system should display a connection alert for a given peripheral, if the application is suspended
    /// when a successful connection is made.
    let notifyOnConnection: Bool
    
    /// A Bool indicating that the system should display a disconnection alert for a given peripheral, if the application
    /// is suspended at the time of the disconnection.
    let notifyOnDisconnection: Bool
    
    /// A String containing a unique identifier (UID) for the `CBCentralManager` that is being instantiated. This UID is used
    /// by the system to identify a specific `CBCentralManager` instance for restoration and, therefore, must remain the same for
    /// subsequent application executions in order for the manager to be restored.
    let restoreIdentifier: String?
    
    public init(showPowerAlert: Bool, notifyOnConnection: Bool, notifyOnDisconnection: Bool, restoreIdentifier: String?) {
        self.showPowerAlert = showPowerAlert
        self.notifyOnConnection = notifyOnConnection
        self.notifyOnDisconnection = notifyOnDisconnection
        self.restoreIdentifier = restoreIdentifier
    }
    
    var asDictionary: [String: Any] {
        var dict = [String: Any]()
        
        dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
        dict[CBConnectPeripheralOptionNotifyOnConnectionKey] = NSNumber(booleanLiteral: notifyOnConnection)
        dict[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = NSNumber(booleanLiteral: notifyOnDisconnection)
        dict[CBCentralManagerOptionShowPowerAlertKey] = NSNumber(booleanLiteral: showPowerAlert)
        
        return dict
    }
}
