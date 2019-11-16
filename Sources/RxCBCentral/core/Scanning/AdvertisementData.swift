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

/// Defines convenience accessors for advertisement fields.
public struct AdvertisementData {
    /// A `String` containing the local name of a peripheral.
    /// - seeAlso: `CBAdvertisementDataLocalNameKey`.
    public let localName: String?
    
    /// An `Int` containing the transmit power of a peripheral.
    /// - seeAlso: `CBAdvertisementDataTxPowerLevelKey`
    public let txPowerLevel: NSNumber?
    
    /// A list of one or more `CBUUID` objects, representing `Service` UUIDs.
    /// - seeAlso: `CBAdvertisementDataServiceUUIDsKey`
    public let serviceUUIDs: [CBUUID]?
    
    /// A dictionary containing service-specific advertisement data. Keys are `CBUUID` objects, representing
    /// `Service` UUIDs. Values are `Data` objects.
    /// - seeAlso: `CBAdvertisementDataServiceDataKey`
    public let serviceData: [CBUUID: Data]?
    
    /// A `Data` object containing the manufacturer data of a peripheral.
    /// - seeAlso: `CBAdvertisementDataManufacturerDataKey`
    public let manufacturerData: Data?
    
    ///  A list of one or more `CBUUID` objects, representing `Service` UUIDs that were
    /// found in the "overflow" area of the advertising data. Due to the nature of the data stored in this area,
    /// UUIDs listed here are "best effort" and may not always be accurate.
    /// - seeAlso: `CBAdvertisementDataOverflowServiceUUIDsKey`
    public let overflowServiceUUIDs: [CBUUID]?
    
    /// A Bool indicating whether or not the advertising event type was connectable. This can be used to determine
    /// whether or not a peripheral is connectable in that instant.
    /// - seeAlso: `CBAdvertisementDataIsConnectable`
    public let isConnectable: Bool?
    
    /// A list of one or more `CBUUID` objects, representing `Service` UUIDs.
    /// - seeAlso: `CBAdvertisementDataSolicitedServiceUUIDsKey`
    public let solicitedServiceUUIDs: [CBUUID]?
    
    init(_ dict: [String: Any]) {
        localName = dict[CBAdvertisementDataLocalNameKey] as? String
        txPowerLevel = dict[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
        serviceUUIDs = dict[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        serviceData = dict[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
        manufacturerData = dict[CBAdvertisementDataManufacturerDataKey] as? Data
        overflowServiceUUIDs = dict[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
        isConnectable = (dict[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        solicitedServiceUUIDs = dict[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}
