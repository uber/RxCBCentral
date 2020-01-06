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
import RxBlocking
@testable import RxCBCentral
import RxSwift
import RxTest
import XCTest

private final class RxPeripheralManagerTests: XCTestCase {
    private var testScheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    private var rxPeripheral: RxPeripheralMock!
    
    private var peripheralManager: RxPeripheralManager!
    
    override func setUp() {
        super.setUp()
        
        testScheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        
        rxPeripheral = RxPeripheralMock()
        peripheralManager = RxPeripheralManager()
        
        peripheralManager.rxPeripheral = rxPeripheral
    }
    
    func test_isConnected() {
        // crete connection observer
        let isConnectedObserver = testScheduler.createObserver(Bool.self)
        
        // record events for testing
        peripheralManager.isConnected
            .bind(to: isConnectedObserver)
            .disposed(by: disposeBag)
            
        // create fake connection events
        let isConnectedEvents: [Recorded<Event<Bool>>] = [
            .next(10, true),
            .next(15, true),
            .next(20, false),
            .next(30, false),
            .next(50, true),
            .completed(100)
        ]
        
        // trigger
        testScheduler.createColdObservable(isConnectedEvents)
            .bind(to: rxPeripheral.isConnectedSubject)
            .disposed(by: disposeBag)
        
        let expected: [Recorded<Event<Bool>>] = [
            .next(10, true),
            .next(20, false),
            .next(50, true),
        ]
        
        testScheduler.start()
        
        XCTAssertEqual(isConnectedObserver.events, expected)
    }
    
    func test_receiveNotifications_validPeripheral() {
        rxPeripheral.notificationDataHandler = { cbuuid -> Observable<Data> in
            guard cbuuid.uuidString == "180D" else { return Observable.just(Data([1])) }
            
            return Observable.just(Data([1, 2, 3]))
        }
        
        let dataObserver = testScheduler.createObserver(Data.self)
        
        peripheralManager.receiveNotifications(for: CBUUID(string: "0x180D"))
            .bind(to: dataObserver)
            .disposed(by: disposeBag)
    
        let expectation: [Recorded<Event<Data>>] = [
            .next(0, Data([1, 2, 3])),
        ]
        
        XCTAssertEqual(dataObserver.events, expectation)
    }
    
    func test_receiveNotications_noPeripheral() throws {
        peripheralManager.rxPeripheral = nil
        
        rxPeripheral.notificationDataHandler = { cbuuid -> Observable<Data> in
            guard cbuuid.uuidString == "180D" else { return Observable.just(Data([1])) }
            
            return Observable.just(Data([1, 2, 3]))
        }
        
        XCTAssertNil(try? peripheralManager.receiveNotifications(for: CBUUID(string: "0x180D")).toBlocking(timeout: 1).first())
    }
    
    func test_queue() {
        let operation = Read(service: CBUUID(string: "0x180D"), characteristic: CBUUID(string: "0x2A37"), timeoutSeconds: .seconds(60), scheduler: testScheduler)
        
        rxPeripheral.readHandler = { (_, _) -> Single<Data?> in
            return Single.just(Data([1,2,3]))
        }
        
        let dataObserver = testScheduler.createObserver(Data?.self)
        
        peripheralManager.queue(operation: operation)
            .asObservable()
            .bind(to: dataObserver)
            .disposed(by: disposeBag)
        
        let expectation: [Recorded<Event<Data?>>] = [
            .next(0, Data([1, 2, 3])),
            .completed(0)
        ]
        
        XCTAssertEqual(dataObserver.events, expectation)
    }
}
