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
@testable import RxCBCentral
import RxSwift
import RxTest
import XCTest

final class BluetoothDetectorTests: XCTestCase {
    
    private var testScheduler: TestScheduler!
    private var disposeBag: DisposeBag!
    
    private var centralDelegate: RxCentralDelegateMock!
    private var bluetoothDetector: BluetoothDetector!
    
    override func setUp() {
        super.setUp()
        testScheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        
        centralDelegate = RxCentralDelegateMock()
        bluetoothDetector = BluetoothDetector(centralManager: CBCentralManagerTypeMock(),
                                              delegate: centralDelegate,
                                              options: BluetoothDetectorOptions(showPowerAlert: false))
    }
    
    func test_bluetoothCapabilities() {
        let bluetoothObserver = testScheduler.createObserver(BluetoothCapability.self)
        
        bluetoothDetector.bluetoothCapability
            .bind(to: bluetoothObserver)
            .disposed(by: disposeBag)
        
        let bluetoothEvents: [Recorded<Event<BluetoothCapability>>] = [
            .next(10, .enabled),
            .next(15, .disabled),
            .next(20, .unsupported),
            .next(25, .unauthorized),
            .next(30, .unknown),
            .next(35, .enabled),
            .next(40, .enabled)
        ]
        
        testScheduler.createColdObservable(bluetoothEvents)
            .bind(to: centralDelegate.bluetoothCapabilitySubject)
            .disposed(by: disposeBag)
        
        let expected: [Recorded<Event<BluetoothCapability>>] = [
            .next(10, .enabled),
            .next(15, .disabled),
            .next(20, .unsupported),
            .next(25, .unauthorized),
            .next(30, .unknown),
            .next(35, .enabled),
            .next(40, .enabled)
        ]
        
        testScheduler.start()
        
        XCTAssertEqual(bluetoothObserver.events, expected)
    }
    
    func test_bluetoothEnabled() {
        let bluetoothObserver = testScheduler.createObserver(Bool.self)
        
        bluetoothDetector.enabled
            .bind(to: bluetoothObserver)
            .disposed(by: disposeBag)
        
        let bluetoothEvents: [Recorded<Event<BluetoothCapability>>] = [
            .next(10, .enabled),
            .next(15, .disabled),
            .next(20, .unsupported),
            .next(25, .unauthorized),
            .next(30, .unknown),
            .next(35, .enabled),
            .next(40, .enabled)
        ]
        
        testScheduler.createColdObservable(bluetoothEvents)
            .bind(to: centralDelegate.bluetoothCapabilitySubject)
            .disposed(by: disposeBag)
        
        let expected: [Recorded<Event<Bool>>] = [
            .next(10, true),
            .next(15, false),
            .next(35, true),
        ]
        
        testScheduler.start()
        
        XCTAssertEqual(bluetoothObserver.events, expected)
    }
}
