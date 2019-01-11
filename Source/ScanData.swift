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

/// @CreateMocks
public protocol ScanData {
    /// Get the RSSI of the advertisement
    var RSSI: Int { get }

    /// Returns the name of the device, if received or an empty string otherwise.
    ///
    /// This is based on complete or shortened local name entries, with complete name used for
    /// preference.
    var deviceName: String { get }

    /// Return a set of BLE services found in advertising data
    var services: Set<UUID> { get }

    /// Returns the name of the device, if received or an empty string otherwise.
    ///
    /// This is based on complete or shortened local name entries, with complete name used for
    /// preference.
    var name: String { get }

    /// Return true if advertising data with dataType was received.
    ///
    /// Data type should match the Extended Inquiry Response Data Types from BLE assigned numbers
    /// document.
    ///
    /// - parameter dataType: Extended Inquiry Response Data Type from BLE assigned numbers
    /// - returns: true if advertising data exists for the data type.
    func hasAdvertisingDataType(dataType: UInt8) -> Bool

    /// Return RAW advertising data (EIR) based on data type
    /// - parameter dataType: AdvdataType of EIR
    /// - returns: raw EIR data or nil if not received
    func advertisingData(dataType: UInt8) -> Data?

    /// Check if service was advertised.
    /// - parameter svc: UUID of service
    /// - returns: true if service was advertised.
    func hasService(svc: UUID) -> Bool

    /// Check if manufacturer data for a given manufacturerId was received.
    /// - parameter manufacturerId: the manufacturer id.
    /// - returns: true if manufacturer data is present.
    func hasManufacturerData(manufacturerId: UInt8) -> Bool

    /// Get manufacturer data for ID
    ///
    /// First byte (the ID) has been parsed away from received data.
    /// - parameter manufacturerId: the manufacturer id.
    /// - returns: manufacturer data or nil if not received.
    func getManufacturerData(manufacturerId: UInt8) -> Data?

    /// All manufacturer data
    var manufacturerData: Data? { get }
}
