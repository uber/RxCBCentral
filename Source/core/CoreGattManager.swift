
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
import RxCocoa
import RxSwift

public class CoreGattManager: GattManager {
    
    public var isConnected: Observable<Bool> {
        return _gattRelay
            .flatMapLatest { Observable.just($0?.isConnected ?? false) }
            .startWith(false)
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
    
    
    // TODO: implement GattManager notifications
    public func receiveNotifications(for service: CBUUID, characteristic: CBUUID) -> Observable<Data> {
//        return _gattRelay
//            .filterNil()
//            .flatMapLatest { (gattIO: GattIO) -> Completable in
//                return gattIO.registerForNotification(service: service, characteristic: characteristic, preprocessor: nil)
//            }
//            .asObservable()
        
        return Observable.just(Data())
    }
    
//    public func receiveNotifications(for service: CBUUID, characteristic: CBUUID) -> Observable<Data> {
//
//        return _gattIOSubject
//            .flatMapLatest { $0.registerForNotification(service: service, characteristic: characteristic) }
//    }
    
    public func accept(gattIO: GattIO) {
        _gattRelay.accept(gattIO)
        
        synchronized(_queueSync) {
            executeNext()
        }
    }
    
    /// If the queue isn't empty and we're not already running an operation, qequeues an operation and executes it
    private func executeNext() {
        guard let gattIO = _gattRelay.value, _currentOperation == nil else { return }
        
        _currentOperation = _operationQueue.dequeue()
        _currentOperation?.execute(gattIO: gattIO)
    }
    
    // TODO: add to a helper class
    // Helper function for executing synchronous, threadsafe closures
    private func synchronized(_ object: Any, _ closure: () -> ()) {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        closure()
    }
    
    private let _gattRelay = BehaviorRelay<GattIO?>(value: nil)
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
        return _source.removeFirst()
    }
    
    var isEmpty: Bool {
        return _source.isEmpty
    }
    
    private var _source = [GattOperationExecutable]()
}

extension ObservableType {
    func doFinally(_ finally: @escaping () -> ()) -> Observable<E> {
        return `do`(onError: { _ in finally() },
                    onCompleted: finally,
                    onDispose: finally)
    }
}
