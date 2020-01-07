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
import RxBlocking
import RxSwift
import RxTest
import XCTest

private final class ConnectionManagerTests: XCTestCase {
    
    private let peripheralGattManager = RxPeripheralManagerTypeMock()
    private let centralManager = CBCentralManagerTypeMock()
    private let delegate = RxCentralDelegateMock()
    
    private var disposeBag: DisposeBag!
    private var testScheduler: TestScheduler!
    
    private var connectionManager: ConnectionManagerType!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
        testScheduler = TestScheduler(initialClock: 0)
        
        connectionManager = ConnectionManager(peripheralGattManager: peripheralGattManager,
                                              centralManager: centralManager,
                                              delegate: delegate,
                                              options: ConnectionManagerOptions(showPowerAlert: false),
                                              scheduler: testScheduler)
    }
    
    func test_scan_allDiscoveredPeripherals() {
        delegate.bluetoothCapability = BehaviorSubject<BluetoothCapability>.init(value: .enabled)
        
        let scanObserver = testScheduler.createObserver(TestScanData.self)
        
        connectionManager
            .scan(for: nil, scanMatcher: nil, options: nil, scanTimeout: .seconds(100))
            .map { (peripheral, advertisementData, RSSI) -> TestScanData in
                return TestScanData(peripheral.identifier, advertisementData.localName, RSSI)
            }
            .bind(to: scanObserver)
            .disposed(by: disposeBag)
                
        // create fake peripheral scan discovery data
        let identifier1 = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let name1 = "TestName1"
        let scan1 = (CBPeripheralTypeMock(identifier: identifier1, state: .disconnected),
                     AdvertisementData([CBAdvertisementDataLocalNameKey: name1]),
                     NSNumber(value: -50))
                
        // create second peripheral scan discovery
        let identifier2 = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5A")!
        let name2 = "TestName2"
        let scan2 = (CBPeripheralTypeMock(identifier: identifier2, state: .disconnected),
                     AdvertisementData([CBAdvertisementDataLocalNameKey: name2]),
                     NSNumber(value: -100))
        
        let scanDiscoveryEvents: [Recorded<Event<ScanData>>] = [
          .next(10, scan1),
          .next(20, scan2),
        ]
        
        testScheduler.createColdObservable(scanDiscoveryEvents)
            .bind(to: delegate.didDiscoverPeripheralSubject)
            .disposed(by: disposeBag)
                
        testScheduler.start()
        
        let expected: [Recorded<Event<TestScanData>>] = [
            .next(10, TestScanData(identifier1, name1, -50)),
            .next(20, TestScanData(identifier2, name2, -100)),
            .error(120, ConnectionManagerError.scanTimeout) // ensure the scan times out properly
        ]
        
        XCTAssertEqual(scanObserver.events, expected)
    }
    
    func test_scan_bluetoothDisabled() {
        delegate.bluetoothCapability = BehaviorSubject<BluetoothCapability>.init(value: .disabled)
        
        let scanObserver = testScheduler.createObserver(TestScanData.self)
        
        connectionManager
            .scan(for: nil, scanMatcher: nil, options: nil)
            .map { (peripheral, advertisementData, RSSI) -> TestScanData in
                return TestScanData(peripheral.identifier, advertisementData.localName, RSSI)
            }
            .bind(to: scanObserver)
            .disposed(by: disposeBag)

        // create fake peripheral scan discovery data
        let testPeripheral = CBPeripheralTypeMock(identifier: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, state: .disconnected)
        let testAdvertisement = AdvertisementData([CBAdvertisementDataLocalNameKey: "TestName1"])
        let testRSSI = NSNumber(value: -50)
        
        let scanDiscoveryEvents: [Recorded<Event<ScanData>>] = [
          .next(10, (testPeripheral, testAdvertisement, testRSSI)),
        ]
        
        testScheduler.createColdObservable(scanDiscoveryEvents)
            .bind(to: delegate.didDiscoverPeripheralSubject)
            .disposed(by: disposeBag)
        
        testScheduler.start()
                
        let expected: [Recorded<Event<TestScanData>>] = [
            .error(1, ConnectionManagerError.bluetoothDisabled)
        ]

        // validate error, bluetooth was disabled
        XCTAssertEqual(scanObserver.events, expected)
    }
    
    func test_connectionState_disconnectWithError() {
        // enable bluetooth
        delegate.bluetoothCapability = BehaviorSubject<BluetoothCapability>.init(value: .enabled)
        
        // scan + connect to trigger connectionState changes
        let rxPeripheralObserver = testScheduler.createObserver(String.self)
        
        connectionManager
            .connectToPeripheral(with: nil, scanMatcher: nil, options: nil, scanTimeout: .seconds(100))
            .map { $0.deviceName ?? "none" }
            .bind(to: rxPeripheralObserver)
            .disposed(by: disposeBag)
        
        // observe connection state and bind
        let connectionStateObserver = testScheduler.createObserver(ConnectionState.self)

        connectionManager
            .connectionState
            .bind(to: connectionStateObserver)
            .disposed(by: disposeBag)

        // produce peripheral discovery event
        let peripheral = CBPeripheralTypeMock(identifier: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, state: .disconnected)
        peripheral.name = "TestName1"
        
        let scanEvents: [Recorded<Event<ScanData>>] = [
            .next(10, (peripheral, AdvertisementData([CBAdvertisementDataLocalNameKey: "TestName1"]), NSNumber(value: -50)))
        ]
        
        testScheduler.createColdObservable(scanEvents)
            .bind(to: delegate.didDiscoverPeripheralSubject)
            .disposed(by: disposeBag)

        // produce peripheral connection event
        let connectionEvents: [Recorded<Event<CBPeripheralType>>] = [
            .next(15, peripheral)
        ]
        
        testScheduler.createColdObservable(connectionEvents)
            .bind(to: delegate.didConnectToPeripheralSubject)
            .disposed(by: disposeBag)

        // produce peripheral disconnection w/ error event
        let disconnectionEvents: [Recorded<Event<(CBPeripheralType, Error?)>>] = [
            .next(20, (peripheral, ConnectionManagerError.connectionFailed))
        ]

        testScheduler.createColdObservable(disconnectionEvents)
            .bind(to: delegate.didDisconnectPeripheralSubject)
            .disposed(by: disposeBag)
                
        let expectedStates: [Recorded<Event<ConnectionState>>] = [
            .next(0, .scanning),
            .next(10, .connecting(peripheral)),
            .next(15, .connected(peripheral)),
            .next(20, .disconnected(ConnectionManagerError.connectionFailed))
        ]
        
        let expectedRxPeripheralName: [Recorded<Event<String>>] = [
            .next(15, "TestName1"),
            .error(20, ConnectionManagerError.connectionFailed)
        ]
        
        testScheduler.start()
        
        XCTAssertEqual(connectionStateObserver.events, expectedStates)
        XCTAssertEqual(rxPeripheralObserver.events, expectedRxPeripheralName)
    }
    
    func test_connectionState_disconnect() {
        // enable bluetooth
        delegate.bluetoothCapability = BehaviorSubject<BluetoothCapability>.init(value: .enabled)
        
        // scan + connect to trigger connectionState changes
        let rxPeripheralObserver = testScheduler.createObserver(String.self)
        
        
        connectionManager
            .connectToPeripheral(with: nil, scanMatcher: nil, options: nil, scanTimeout: .seconds(100))
            .map { $0.deviceName ?? "none" }
            .bind(to: rxPeripheralObserver)
            .disposed(by: disposeBag)
        
        // observe connection state and bind
        let connectionStateObserver = testScheduler.createObserver(ConnectionState.self)

        connectionManager
            .connectionState
            .bind(to: connectionStateObserver)
            .disposed(by: disposeBag)

        // produce peripheral discovery event
        let peripheral = CBPeripheralTypeMock(identifier: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, state: .disconnected)
        peripheral.name = "TestName1"
        
        let scanEvents: [Recorded<Event<ScanData>>] = [
            .next(10, (peripheral, AdvertisementData([CBAdvertisementDataLocalNameKey: "TestName1"]), NSNumber(value: -50)))
        ]
        
        testScheduler.createColdObservable(scanEvents)
            .bind(to: delegate.didDiscoverPeripheralSubject)
            .disposed(by: disposeBag)

        // produce peripheral connection event
        let connectionEvents: [Recorded<Event<CBPeripheralType>>] = [
            .next(15, peripheral)
        ]
        
        testScheduler.createColdObservable(connectionEvents)
            .bind(to: delegate.didConnectToPeripheralSubject)
            .disposed(by: disposeBag)

        // produce normal peripheral disconnection
        let disconnectionEvents: [Recorded<Event<(CBPeripheralType, Error?)>>] = [
            .next(20, (peripheral, nil))
        ]

        testScheduler.createColdObservable(disconnectionEvents)
            .bind(to: delegate.didDisconnectPeripheralSubject)
            .disposed(by: disposeBag)
                
        let expectedStates: [Recorded<Event<ConnectionState>>] = [
            .next(0, .scanning),
            .next(10, .connecting(peripheral)),
            .next(15, .connected(peripheral)),
            .next(20, .disconnected(nil))
        ]
        
        let expectedRxPeripheralName: [Recorded<Event<String>>] = [
            .next(15, "TestName1"),
            .next(20, "TestName1"),
        ]
        
        testScheduler.start()
        
        testScheduler.advanceTo(TestScheduler.Defaults.disposed)
        XCTAssertEqual(connectionStateObserver.events, expectedStates)
        XCTAssertEqual(rxPeripheralObserver.events, expectedRxPeripheralName)
    }
}

fileprivate struct TestScanData: Equatable {
    init(_ uuid: UUID, _ advertisement: String?, _ RSSI: NSNumber) {
        self.uuid = uuid
        self.advertisement = advertisement
        self.RSSI = RSSI
    }
    
    static func == (lhs: TestScanData, rhs: TestScanData) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.advertisement == rhs.advertisement &&
            lhs.RSSI == rhs.RSSI
    }
    
    let uuid: UUID
    let advertisement: String?
    let RSSI: NSNumber
}
