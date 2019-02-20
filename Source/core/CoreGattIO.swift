
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
import RxOptional
import RxSwift

class CoreGattIO: NSObject, GattIO, CBPeripheralDelegate {
    
    public init(peripheral: CBPeripheral, connectionState: Observable<ConnectionManagerState>) {
        self.connectionState = connectionState
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    public var isConnected: Bool {
        return peripheral.state == .connected
    }
    
    public var deviceName: String? {
        return self.peripheral.name
    }
    
    // MARK: - GattIO
    
    // TODO: assumes all writes are without response for now to calculate MTU
    public var maxWriteLength: Int {
       return peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withoutResponse)
    }
    
    public func readRSSI() -> Single<Int> {        
        return didReadRSSISubject
            .take(1)
            .asSingle()
            .do(onSubscribe: {
                self.peripheral.readRSSI()
            })
    }
    
    public func read(service: CBUUID, characteristic: CBUUID) -> Single<Data?> {
        
        let sharedReadDataObservable: Single<Data?> =
            connectionState
                .flatMapLatest { (state: ConnectionManagerState) -> Observable<([CBService], Error?)> in
                    guard state == .connected else { return Observable.error(GattIOError.notConnected) }
                    return self.didDiscoverServicesSubject.asObservable()
                }
                .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                    let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                    return (matchingService, error)
                }
                .take(1)
                .do(onNext: { (matchingService: CBService?, error: Error?) in
                    if let matchingService = matchingService, error == nil {
                        self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                    }
                })
                .flatMapLatest({ (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                    guard let _ = matchingService else {
                        RxCBLogger.sharedInstance.log("Error: service not found")
                        return Observable.error(GattIOError.serviceNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    
                    return self.didDiscoverCharacteristicsSubject.asObservable()
                })
                .take(1)
                .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                    let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
                    return (characteristic, error)
                }
                .do(onNext: { (matchingCharacteristic: CBCharacteristic?, error: Error?) in
                    if let matchingCharacteristic = matchingCharacteristic, error == nil {
                        self.peripheral.readValue(for: matchingCharacteristic)
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?) -> Observable<(CBCharacteristic, Error?)> in
                    guard let _ = matchingCharacteristic else {
                        RxCBLogger.sharedInstance.log("Error: characteristic not found")
                        return Observable.error(GattIOError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    
                    return self.didUpdateValueForCharacteristicSubject.asObservable()
                }
                .map { (characteristic: CBCharacteristic, error: Error?) -> Data? in
                    RxCBLogger.sharedInstance.log(prefix: "Read data:", data: characteristic.value)
                    return characteristic.value
                }
                .take(1)
                .asSingle()
                .do(onSubscribe: {
                    // add a check if we've already discovered valid services / charac  - update: seems CB caches this, test performance
                    self.peripheral.discoverServices([service])
                })
        
        return sharedReadDataObservable
    }
    
    public func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        
        
        // TODO: don't wait for didWriteToCharacteristicSubject when performing a .writeWithoutResponse to avoid Rx timeout
        let sharedWriteCompletable: Completable =
            connectionState
                .flatMapLatest { (state: ConnectionManagerState) -> Observable<([CBService], Error?)> in
                    guard state == .connected else { return Observable.error(GattIOError.notConnected) }
                    return self.didDiscoverServicesSubject.asObservable()
                }
                .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                    let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                    return (matchingService, error)
                }
                .take(1)
                .do(onNext: { (matchingService: CBService?, error: Error?) in
                    if let matchingService = matchingService, error == nil {
                        self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                    }
                })
                .flatMapLatest({ (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                    guard let _ = matchingService else {
                        RxCBLogger.sharedInstance.log("Error: service not found")
                        return Observable.error(GattIOError.serviceNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    
                    return self.didDiscoverCharacteristicsSubject.asObservable()
                })
                .take(1)
                .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                    let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
                    return (characteristic, error)
                }
                .do(onNext: { (matchingCharacteristic: CBCharacteristic?, error: Error?) in
                    if let matchingCharacteristic = matchingCharacteristic, error == nil {
                        
                        let properties: CBCharacteristicProperties = matchingCharacteristic.properties
                        let writeType = properties.contains(CBCharacteristicProperties.write) ? CBCharacteristicWriteType.withResponse : CBCharacteristicWriteType.withoutResponse
                        
                        // let CB give an error if property isn't writable
                        self.peripheral.writeValue(data, for: matchingCharacteristic, type: writeType)
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?) -> Observable<Error?> in
                    guard let _ = matchingCharacteristic else {
                        RxCBLogger.sharedInstance.log("Error: characteristic not found")
                        return Observable.error(GattIOError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    
                    return self.didWriteToCharacteristicSubject.asObservable()
                }
                .take(1)
                .flatMapLatest { (error: Error?) -> Completable in
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error).asCompletable()
                    }
                    RxCBLogger.sharedInstance.log("Write successful.")
                    return Observable.empty().asCompletable()
                }
                .take(1)
                .ignoreElements()
                .do(onSubscribe: {
                    self.peripheral.discoverServices([service])
                })
        
        
        return sharedWriteCompletable
    }

    public func registerForNotification(service: CBUUID, characteristic: CBUUID, preprocessor: Preprocessor? = nil) -> Completable {
        let sharedNotifyCompletable: Completable =
            didDiscoverServicesSubject
                .do(onNext: { (services: [CBService], _) in
                    print(services.description)
                })
                .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                    let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                    return (matchingService, error)
                }
                .take(1)
                .do(onNext: { (matchingService: CBService?, error: Error?) in
                    if let matchingService = matchingService, error == nil {
                        self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                    }
                })
                .flatMapLatest({ (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                    guard let _ = matchingService else {
                        return Observable.error(GattIOError.serviceNotFound)
                    }
                    
                    if let error = error {
                        return Observable.error(error)
                    }
                    
                    return self.didDiscoverCharacteristicsSubject.asObservable()
                })
                .take(1)
                .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                    let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
                    return (characteristic, error)
                }
                .do(onNext: { [weak self] (matchingCharacteristic: CBCharacteristic?, error: Error?) in
                    if let self = self, let matchingCharacteristic = matchingCharacteristic, error == nil {
                        // if given a preprocessor, track it with the char UUID
                        if let preprocessor = preprocessor {
                            self.synchronized(self.processSync) {
                                self.preprocessorDict[characteristic] = preprocessor
                            }
                        }
                        
                        // let CB give an error if property isn't notify-able
                        self.peripheral.setNotifyValue(true, for: matchingCharacteristic)
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?)  -> Observable<(CBCharacteristic, Error?)> in
                    guard let _ = matchingCharacteristic else {
                        return Observable.error(GattIOError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        return Observable.error(error)
                    }
                    
                    return self.didUpdateValueForCharacteristicSubject.asObservable()
                }
                .flatMapLatest { (_, error: Error?) -> Completable in
                    if let error = error {
                        return Observable.error(error).asCompletable()
                    }
                    return Observable.empty().asCompletable()
                }
                .take(1)
                .ignoreElements()
                .do(onSubscribe: {
                    self.peripheral.discoverServices([service])
                })
        
        return sharedNotifyCompletable
    }
    
    public func notificationData(for characteristic: CBUUID) -> Observable<Data> {
        return didUpdateValueForCharacteristicSubject
            .filter { (arg: (CBCharacteristic, Error?)) -> Bool in
                let (notifyCharacteristic, error) = arg
                return characteristic.uuidString == notifyCharacteristic.uuid.uuidString && error == nil
            }
            .flatMap { [weak self] (notifyCharacteristic: CBCharacteristic, _) -> Observable<Data?> in
                var processedData: Data? = nil
                
                guard let `self` = self, let data = notifyCharacteristic.value else { return Observable.just(nil) }
                
                self.synchronized(self.processSync) {
                    if let preprocessor = self.preprocessorDict[characteristic] {
                        processedData = preprocessor.process(data: data)
                    }
                }
                
                return Observable.just(processedData)
            }
            .filterNil()
    }

    // TODO: add processor functionality
    public func process(data: Data) -> Data? {
        return nil
    }
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadRSSISubject.onNext(RSSI.intValue)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let servicesData = (peripheral.services ?? [], error)
        didDiscoverServicesSubject.onNext(servicesData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristicsData = (service.characteristics ?? [], error)
        didDiscoverCharacteristicsSubject.onNext(characteristicsData)
    }
    
    /// Invoked when you retrieve a characteristic’s value, or when the peripheral notifies you the value has changed
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let valueData = (characteristic, error)
        didUpdateValueForCharacteristicSubject.onNext(valueData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        didWriteToCharacteristicSubject.onNext(error)
    }
    
    // MARK: - Private
    
    // TODO: move to a helper class to share
    private func synchronized(_ object: Any, _ closure: () -> ()) {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        closure()
    }
    
    private let peripheral: CBPeripheral
    private let connectionState: Observable<ConnectionManagerState>
    private let processSync = NSObject()
    
    // Registered preprocessors mapped to their characteristic's CBUUID
    private var preprocessorDict = [CBUUID: Preprocessor]()
    
    // MARK: - Delegate Subjects
    
    private let didReadRSSISubject = PublishSubject<Int>()
    private let didDiscoverServicesSubject = PublishSubject<([CBService], Error?)>()
    private let didDiscoverCharacteristicsSubject = PublishSubject<([CBCharacteristic], Error?)>()
    private let didUpdateValueForCharacteristicSubject = PublishSubject<(CBCharacteristic, Error?)>()
    private let didWriteToCharacteristicSubject = PublishSubject<Error?>()
}

extension GattIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return NSLocalizedString("No matching service found for connected peripheral.", comment: "GattIO error")
        case .characteristicNotFound:
            return NSLocalizedString("No matching characteristic found for connected peripheral.", comment: "GattIO error")
        case .notConnected:
            return NSLocalizedString("Not connected: cannot perform Gatt operations", comment: "GattIO error")
        }
    }
}

extension CBCharacteristicProperties: CustomDebugStringConvertible {
    public var debugDescription: String {
        let map: [CBCharacteristicProperties.RawValue: String] = [
            CBCharacteristicProperties.broadcast.rawValue: "broadcast",
            CBCharacteristicProperties.read.rawValue: "read",
            CBCharacteristicProperties.writeWithoutResponse.rawValue: "writeWithoutResponse",
            CBCharacteristicProperties.write.rawValue: "write",
            CBCharacteristicProperties.notify.rawValue: "notify",
            CBCharacteristicProperties.indicate.rawValue: "indicate",
            CBCharacteristicProperties.authenticatedSignedWrites.rawValue: "authenticatedSignedWrites",
            CBCharacteristicProperties.extendedProperties.rawValue: "extendedProperties",
            CBCharacteristicProperties.notifyEncryptionRequired.rawValue: "notifyEncryptionRequired",
            CBCharacteristicProperties.indicateEncryptionRequired.rawValue: "indicateEncryptionRequired"
        ]
        
        var toReturn = ""
        
        for (key, value) in map {
            if self.contains(CBCharacteristicProperties(rawValue: key)) {
                toReturn += value + ", "
            }
        }
        
        return toReturn
    }
}
