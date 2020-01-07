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
import RxSwift

public class BluetoothDetector: NSObject, BluetoothDetectorType {
    
    init(centralManager: CBCentralManagerType, delegate: RxCentralDelegate, options: BluetoothDetectorOptions?) {
        _centralManager = centralManager
        _delegate = delegate
        _options = options
        _centralManager.delegate = delegate
    }
    
    public convenience init(options: BluetoothDetectorOptions?) {
        let delegate = RxCentralDelegateImpl()
        let centralManager = CBCentralManager(delegate: nil, queue: nil, options: options?.asDictionary)
        
        self.init(centralManager: centralManager, delegate: delegate, options: options)
    }
    
    public var bluetoothCapability: Observable<BluetoothCapability> {
        return _delegate.bluetoothCapability
    }
    
    public var enabled: Observable<Bool> {
        return _delegate.bluetoothCapability
            .map { $0 == .enabled }
            .distinctUntilChanged()
    }
    
    // MARK: - Private
    
    private let _options: BluetoothDetectorOptions?
    private let _delegate: RxCentralDelegate
    
    private let _centralManager: CBCentralManagerType
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .disabled:
            return NSLocalizedString("Bluetooth is disabled.", comment: "Bluetooth error")
        case .unsupported:
            return NSLocalizedString("Bluetooth is unsupported by this device.", comment: "Bluetooth error")
        }
    }
}
