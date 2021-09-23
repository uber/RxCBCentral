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
	
	func test_queue_enqueueSeveralOperations_executesInOrder() {
		// Create 3 payloads which will be sent simultaneously to peripheral
		let payload1 = "Packet 1 containing dummy data"
		let payload2 = "Packet 2 containing slightly more dummy data than first packet"
		let payload3 = "P3"
		
		guard let p1Data = payload1.data(using: .utf8),
			  let p2Data = payload2.data(using: .utf8),
			  let p3Data = payload3.data(using: .utf8) else {
			XCTFail()
			return
		}
		
		// Payloads are meant to be sent serially one after each other
		let expectedBlob = p1Data + p2Data + p3Data
		// Payload received on 'receiving' side
		var receivedBlob = Data()
		
		// Simulate peripheral with small write length so packets will be fragmented
		rxPeripheral.maxWriteLength = 5
		rxPeripheral.writeHandler = { _, _, data -> Completable in
			// Simulate delay as it takes time to connect/discover, return 'successful' transfer.
			return Observable.empty()
				.delay(
					RxTimeInterval.milliseconds(100),
					scheduler: self.testScheduler
				)
				.do(onCompleted: { receivedBlob.append(data) })
				.asCompletable()
		}

		// Enqueue write operations
		for payload in [p1Data, p2Data, p3Data] {
			peripheralManager.queue(
				operation: Write(
					service: CBUUID(),
					characteristic: CBUUID(),
					data: payload
				)
			)
			.subscribe({ _ in })
			.disposed(by: disposeBag)
		}
		
		// Start the show
		testScheduler.advanceTo(testScheduler.clock + 100)
		
		XCTAssertEqual(expectedBlob, receivedBlob)
	}
}
