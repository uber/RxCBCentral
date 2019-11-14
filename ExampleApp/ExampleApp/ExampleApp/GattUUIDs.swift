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
