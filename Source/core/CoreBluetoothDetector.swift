
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
import RxSwift

public struct BluetoothDetectorOptions {
    
    /// A Bool indicating that the system should, if Bluetooth is powered off when `CBCentralManager` is instantiated, display
    /// a warning dialog to the user.
    let showPowerAlert: Bool
    
    var asDictionary: [String: Any] {
        return [CBCentralManagerOptionShowPowerAlertKey : NSNumber(booleanLiteral: showPowerAlert)]
    }
}

public class CoreBluetoothDetector: NSObject, BluetoothDetector, CBCentralManagerDelegate {
    
    public required init(options: BluetoothDetectorOptions?) {
        self._options = options
        super.init()
        
        _centralManager = CBCentralManager(delegate: self, queue: nil, options: _options?.asDictionary)
    }
    
    public var capability: Observable<Capability> {
        return _capabilitySubject.asObservable()
    }
    
    public var enabled: Observable<Bool> {
        return _enabledSubject.asObservable()
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            RxCBLogger.sharedInstance.log("Bluetooth powered off.")
            _enabledSubject.onNext(false)
            _capabilitySubject.onNext(.disabled)
        case .poweredOn:
            RxCBLogger.sharedInstance.log("Bluetooth powered on.")
            _enabledSubject.onNext(true)
            _capabilitySubject.onNext(.enabled)
        case .resetting:
            _enabledSubject.onNext(false)
            _capabilitySubject.onNext(.disabled)
        case .unauthorized:
            _enabledSubject.onNext(false)
            _capabilitySubject.onNext(.unsupported)
        case .unknown:
            _enabledSubject.onNext(false)
            _capabilitySubject.onNext(.unsupported)
        case .unsupported:
            _enabledSubject.onNext(false)
            _capabilitySubject.onNext(.unsupported)
        }
    }

    // MARK: - Private
    
    private let _options: BluetoothDetectorOptions?
    
    private var _centralManager: CBCentralManager!
    
    private let _capabilitySubject = ReplaySubject<Capability>.create(bufferSize: 1)
    private let _enabledSubject = ReplaySubject<Bool>.create(bufferSize: 1)
}
