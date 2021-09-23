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
import RxCocoa
import RxSwift

open class RxPeripheralManager: RxPeripheralManagerType {
    
    public init() {}
    
    public weak var rxPeripheral: RxPeripheral? {
        didSet {
            _peripheralRelay.accept(rxPeripheral)
            
            synchronized(_queueSync) {
                executeNext()
            }
        }
    }
    
    public var isConnected: Observable<Bool> {
        return _peripheralRelay
            .flatMapLatest { $0?.isConnected ?? Observable.just(false) }
            .distinctUntilChanged()
    }
    
    public func queue<O: GattOperation>(operation: O) -> Single<O.Element> {
        return operation
            .result
            .do(onSubscribe: {
                self.synchronized(self._queueSync) {
                    self._operationQueue.enqueue(operation)
                    self.executeNext()
                }
            })
            .asObservable()
            .doFinally {
                self.synchronized(self._queueSync) {
                    self._currentOperation = nil
                    self.executeNext()
                }
            }
            .asSingle()
    }
    
    public func receiveNotifications(for characteristic: CBUUID) -> Observable<Data> {
        return _peripheralRelay
            .filterNil()
            .flatMapLatest { (peripheral: RxPeripheral) -> Observable<Data> in
                return peripheral.notificationData(for: characteristic)
        }
    }
    
    /// If the queue isn't empty and we're not already running an operation, queue an operation and execute it
    private func executeNext() {
        guard let peripheral = _peripheralRelay.value, _currentOperation == nil else { return }
        
        _currentOperation = _operationQueue.dequeue()
        _currentOperation?.execute(with: peripheral)
    }
    
    // TODO: add to a helper class
    // Helper function for executing synchronous, threadsafe closures
    private func synchronized(_ object: Any, _ closure: () -> ()) {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        closure()
    }
    
    private let _peripheralRelay = BehaviorRelay<RxPeripheral?>(value: nil)
    private let _queueSync: NSObject = NSObject()
    private var _currentOperation: GattOperationExecutable?
    private var _operationQueue = GattQueue()
}

/// Queue for GattOperations. Simple wrapper around Array
fileprivate struct GattQueue {
    mutating func enqueue(_ operation: GattOperationExecutable) {
        _source.append(operation)
    }
    
    mutating func dequeue() -> GattOperationExecutable? {
        guard _source.count > 0 else { return nil }
        return _source.removeFirst()
    }
    
    var isEmpty: Bool {
        return _source.isEmpty
    }
    
    private var _source = [GattOperationExecutable]()
}

extension ObservableType {
    func doFinally(_ finally: @escaping () -> ()) -> Observable<Element> {
		var didEmit = false
		let invoke = {
			guard !didEmit else { return }
			didEmit = true
			finally()
		}
		
		return `do`(onError: { _ in invoke() },
					onCompleted: invoke,
					onDispose: invoke)
    }
}
