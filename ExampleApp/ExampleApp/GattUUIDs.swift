//
//  GattUUIDs.swift
//  ExampleApp
//
//  Created by Joseph Soultanis on 2/15/19.
//  Copyright © 2019 Joseph Soultanis. All rights reserved.
//

import CoreBluetooth

public struct GattUUIDs {
    public static let GAP_SVC_UUID = CBUUID(string: "0x1800")
    public static let GAP_DEVICE_NAME_UUID = CBUUID(string: "0x2A00")
    public static let BATTERY_SVC_UUID = CBUUID(string: "0x180F")
    public static let BATTERY_LEVEL_UUID = CBUUID(string: "0x2A19")
    public static let DIS_SVC_UUID = CBUUID(string: "0x180A")
    public static let DIS_MFG_NAME_UUID = CBUUID(string: "0x2A29")
    public static let DIS_MODEL_UUID = CBUUID(string: "0x2A24")
    public static let DIS_SERIAL_UUID = CBUUID(string: "0x2A25")
    public static let DIS_FIRMWARE_UUID = CBUUID(string: "0x2A26")
    public static let DIS_HARDWARE_UUID = CBUUID(string: "0x2A27")
}
