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

@testable import RxCBCentral
import XCTest
import CoreBluetooth
import RxBlocking
import RxTest
import XCTest
import RxSwift

final class RxPeripheralTests: XCTestCase {

    let disposeBag = DisposeBag()

    lazy var connectionStateMock = PublishSubject<ConnectionState>()
    lazy var didUpdateValueForCharacteristicSubject = PublishSubject<(CBCharacteristic, Error?)>()
    lazy var peripheralTypeMock = CBPeripheralTypeMock()
    private var testScheduler = TestScheduler(initialClock: 0)

    lazy var peripheral = RxPeripheralImpl(peripheral: peripheralTypeMock,
                                           connectionState: connectionStateMock.asObservable(),
                                           didUpdateValueForCharacteristicSubject: didUpdateValueForCharacteristicSubject)

    override func setUp() {
        super.setUp()
    }

    func test_notificationData_whenPrepProcessorNil_returnsData() {

        let notificationsObserver = testScheduler.createObserver(Data?.self)

        peripheral.notificationData(for: CBUUID(string: "0x2465"))
            .bind(to: notificationsObserver)
            .disposed(by: self.disposeBag)

        let characteristic = CBMutableCharacteristic(type: CBUUID(string: "0x2465"),
                                           properties: CBCharacteristicProperties.notify,
                                           value: Data(base64Encoded: "aGFja3RvYmVyZmVzdA=="),
                                           permissions: CBAttributePermissions.readable)

        didUpdateValueForCharacteristicSubject.onNext((characteristic, nil))

        let expected: [Recorded<Event<Data?>>] = [ .next(0, Data(base64Encoded: "aGFja3RvYmVyZmVzdA==")) ]

        XCTAssertEqual(notificationsObserver.events, expected)
    }

}

public class CBPeripheralTypeMock: CBPeripheralType {
    public init() { }
    public init(delegate: CBPeripheralDelegate? = nil, name: String? = nil, identifier: UUID = UUID(), state: CBPeripheralState) {
        self.delegate = delegate
        self.name = name
        self.identifier = identifier
        self._state = state
    }

    public var delegateSetCallCount = 0
    public var delegate: CBPeripheralDelegate? = nil { didSet { delegateSetCallCount += 1 } }

    public var nameSetCallCount = 0
    public var name: String? = nil { didSet { nameSetCallCount += 1 } }

    public var identifierSetCallCount = 0
    public var identifier: UUID = UUID() { didSet { identifierSetCallCount += 1 } }

    public var stateSetCallCount = 0
    private var _state: CBPeripheralState!  { didSet { stateSetCallCount += 1 } }
    public var state: CBPeripheralState {
        get { return _state }
        set { _state = newValue }
    }

    public var readRSSICallCount = 0
    public var readRSSIHandler: (() -> ())?
    public func readRSSI()  {
        readRSSICallCount += 1
        if let readRSSIHandler = readRSSIHandler {
            return readRSSIHandler()
        }
    }

    public var maximumWriteValueLengthCallCount = 0
    public var maximumWriteValueLengthHandler: ((CBCharacteristicWriteType) -> (Int))?
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        maximumWriteValueLengthCallCount += 1
        if let maximumWriteValueLengthHandler = maximumWriteValueLengthHandler {
            return maximumWriteValueLengthHandler(type)
        }
        return 0
    }

    public var discoverServicesCallCount = 0
    public var discoverServicesHandler: (([CBUUID]?) -> ())?
    public func discoverServices(_ serviceUUIDs: [CBUUID]?)  {
        discoverServicesCallCount += 1
        if let discoverServicesHandler = discoverServicesHandler {
            return discoverServicesHandler(serviceUUIDs)
        }
    }

    public var discoverCharacteristicsCallCount = 0
    public var discoverCharacteristicsHandler: (([CBUUID]?, CBService) -> ())?
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)  {
        discoverCharacteristicsCallCount += 1
        if let discoverCharacteristicsHandler = discoverCharacteristicsHandler {
            return discoverCharacteristicsHandler(characteristicUUIDs, service)
        }
    }

    public var readValueCallCount = 0
    public var readValueHandler: ((CBCharacteristic) -> ())?
    public func readValue(for characteristic: CBCharacteristic)  {
        readValueCallCount += 1
        if let readValueHandler = readValueHandler {
            return readValueHandler(characteristic)
        }
    }

    public var writeValueCallCount = 0
    public var writeValueHandler: ((Data, CBCharacteristic, CBCharacteristicWriteType) -> ())?
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)  {
        writeValueCallCount += 1
        if let writeValueHandler = writeValueHandler {
            return writeValueHandler(data, characteristic, type)
        }
    }

    public var setNotifyValueCallCount = 0
    public var setNotifyValueHandler: ((Bool, CBCharacteristic) -> ())?
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)  {
        setNotifyValueCallCount += 1
        if let setNotifyValueHandler = setNotifyValueHandler {
            setNotifyValueHandler(enabled, characteristic)
        }
    }
}
