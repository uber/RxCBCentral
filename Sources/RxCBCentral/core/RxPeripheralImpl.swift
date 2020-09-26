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
import RxOptional
import RxSwift

class RxPeripheralImpl: NSObject, RxPeripheral, CBPeripheralDelegate {
    
    public init(peripheral: CBPeripheralType, connectionState: Observable<ConnectionState>) {
        self.connectionState = connectionState
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    public var isConnected: Observable<Bool> {
        return connectionState
            .map { (state: ConnectionState) -> Bool in
                if case let .connected(peripheral) = state {
                    return self.peripheral.identifier == peripheral.identifier && self.peripheral.state == .connected
                }
                return false
            }
            .distinctUntilChanged()
    }
    
    public var deviceName: String? {
        return self.peripheral.name
    }
    
    // MARK: - RxPeripheral
    
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
        
        return connectionState
            .flatMapLatest { (state: ConnectionState) -> Observable<([CBService], Error?)> in
                guard case let .connected(peripheral) = state,
                    let cbPeripheral = peripheral as? CBPeripheral,
                    cbPeripheral.identifier == self.peripheral.identifier else { return Observable.error(GattError.notConnected) }
                
                // need to rediscover services? seems CB caches this; test performance
                self.peripheral.discoverServices([service])
                
                return self.didDiscoverServicesSubject.asObservable()
            }
            .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                // check that given service exists on the peripheral
                let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                return (matchingService, error)
            }
            .take(1)
            .flatMapLatest { (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                guard let matchingService = matchingService else {
                    RxCBLogger.sharedInstance.log("Error: service not found - \(service.uuidString)")
                    return Observable.error(GattError.serviceNotFound)
                }
                
                if let error = error {
                    RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                    return Observable.error(error)
                }
                
                self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                
                return self.didDiscoverCharacteristicsSubject.asObservable()
            }
            .take(1)
            .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                 // check that given characteristic exists on the peripheral
                let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
                return (characteristic, error)
            }
            .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?) -> Observable<(CBCharacteristic, Error?)> in
                guard let matchingCharacteristic = matchingCharacteristic else {
                    RxCBLogger.sharedInstance.log("Error: characteristic not found - \(characteristic.uuidString)")
                    return Observable.error(GattError.characteristicNotFound)
                }
                
                if let error = error {
                    RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                    return Observable.error(error)
                }
                
                self.peripheral.readValue(for: matchingCharacteristic) // perform the CB read operation
                
                return self.didUpdateValueForCharacteristicSubject.asObservable() // this subject fires from reads and notifications
            }
            .filter { (updatedCharacteristic: CBCharacteristic, error: Error?) -> Bool in
                // filter out data that doesn't match the characteristic we're reading from
                return updatedCharacteristic.uuid.uuidString == characteristic.uuidString
            }
            .map { (characteristic: CBCharacteristic, error: Error?) -> Data? in
                RxCBLogger.sharedInstance.log(prefix: "Read data: ", data: characteristic.value)
                return characteristic.value
            }
            .take(1)
            .asSingle()
    }
    
    public func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        
        // TODO: invesigate handling .writeWithResponse
        return connectionState
            .flatMapLatest { (state: ConnectionState) -> Observable<([CBService], Error?)> in
                guard case let .connected(peripheral) = state,
                    let cbPeripheral = peripheral as? CBPeripheral,
                    cbPeripheral.identifier == self.peripheral.identifier else { return Observable.error(GattError.notConnected) }
                
                self.peripheral.discoverServices([service])
                
                return self.didDiscoverServicesSubject.asObservable()
            }
            .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                return (matchingService, error)
            }
            .take(1)
            .flatMapLatest { (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                guard let matchingService = matchingService else {
                    RxCBLogger.sharedInstance.log("Error: service not found - \(service.uuidString)")
                    return Observable.error(GattError.serviceNotFound)
                }
                
                if let error = error {
                    RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                    return Observable.error(error)
                }
                
                self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                
                return self.didDiscoverCharacteristicsSubject.asObservable()
            }
            .take(1)
            .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
                return (characteristic, error)
            }
            .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?) -> Completable in
                guard let matchingCharacteristic = matchingCharacteristic else {
                    RxCBLogger.sharedInstance.log("Error: characteristic not found - \(characteristic.uuidString)")
                    return Completable.error(GattError.characteristicNotFound)
                }
                
                if let error = error {
                    RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                    return Completable.error(error)
                }
                
                let properties: CBCharacteristicProperties = matchingCharacteristic.properties
                let writeType = properties.contains(CBCharacteristicProperties.write) ? CBCharacteristicWriteType.withResponse : CBCharacteristicWriteType.withoutResponse
                
                // let CB give an error if property isn't writable
                self.peripheral.writeValue(data, for: matchingCharacteristic, type: writeType)
                
                return Observable.empty().asCompletable()
            }
            .ignoreElements()
    }
    
    public func registerForNotification(service: CBUUID, characteristic: CBUUID, preprocessor: Preprocessor? = nil) -> Completable {
            return
                didDiscoverServicesSubject
                .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                    print("RFN ",services.count, services)
                    print("RFN ",services.first?.uuid.uuidString, service.uuidString)
                    let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                    return (matchingService, error)
                }
                .take(1)
                .flatMapLatest { (matchingService: CBService?, error: Error?) -> Observable<([CBCharacteristic], Error?)> in
                    print("MATCHINGSERVICE :",matchingService)
                    guard let matchingService = matchingService else {
                        RxCBLogger.sharedInstance.log("Error: service not found")
                        return Observable.error(GattError.serviceNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    
                    print("CHARACTERISTIC TO SEARCH: ",characteristic)
                    self.peripheral.discoverCharacteristics([characteristic], for: matchingService)
                    
                    return self.didDiscoverCharacteristicsSubject.asObservable()
                }
                .filter
                {   print("FILTER for")
                    print($0,$1)
                    for c in $0{
                        print(c.uuid.uuidString, characteristic.uuidString)
                        if(c.uuid.uuidString == characteristic.uuidString){
                            return true
                        }
                    }
                    return false
                }
                .take(1)
                .map { (characteristics: [CBCharacteristic], error: Error?) -> (CBCharacteristic?, Error?) in
                    print("RFN characteristics ",characteristics.count, characteristics)
                    for c in characteristics {
                        print(c.uuid.uuidString, characteristic.uuidString)
                        if(c.uuid.uuidString == characteristic.uuidString){
                            return (c, error)
                        }
                    }
                    print("not found , what to do, raise an error")
                    return (characteristics.first,GattError.characteristicNotFound)
//                    print("RFN ",characteristics.first?.uuid.uuidString , characteristic.uuidString)
//                    let characteristic = characteristics.first { $0.uuid.uuidString == characteristic.uuidString }
//                    return (characteristic, error)
                }
                .do(onNext: { [weak self] (_, error: Error?) in
                    if let self = self, error == nil {
                        // if given a preprocessor, track it with the char UUID
                        if let preprocessor = preprocessor {
                            self.synchronized(self.processSync) {
                                self.preprocessorDict[characteristic] = preprocessor
                            }
                        }
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?)  -> Observable<(CBCharacteristic, Error?)> in
                    print("RFN \(#line)")
                    guard let matchingCharacteristic = matchingCharacteristic else {
                        RxCBLogger.sharedInstance.log("Error: characteristic not found")
                        return Observable.error(GattError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.error(error)
                    }
                    // let CB give an error if property isn't notify-able
                    self.peripheral.setNotifyValue(true, for: matchingCharacteristic)
                    print("RFN \(#line)")
                    return self.didUpdateValueForCharacteristicSubject.asObservable()
                }
                .take(1)
                .flatMapLatest { (_, error: Error?) -> Completable in
                    if let error = error {
                        return Observable.error(error).asCompletable()
                    }
                    print("RFN completed")
                    return Observable.empty().asCompletable()
                }
                .take(1)
                .ignoreElements()
                .do(onSubscribe: {
                    self.peripheral.discoverServices([service])
                })
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
    
    public func hasService(service: CBUUID) -> Observable<Bool> {
            return
                didDiscoverServicesSubject
                .map { (services: [CBService], error: Error?) -> (CBService?, Error?) in
                    print("RFN ",services.count, services)
                    print("RFN ",services.first?.uuid.uuidString, service.uuidString)
                    let matchingService = services.first { $0.uuid.uuidString == service.uuidString }
                    return (matchingService, error)
                }
                .take(1)
                .flatMapLatest { (matchingService: CBService?, error: Error?) -> Observable<Bool> in
                    print("MATCHINGSERVICE :",matchingService)
                    guard let matchingService = matchingService else {
                        RxCBLogger.sharedInstance.log("Error: service not found")
                        return Observable.just(false)
                    }
                    
                    if let error = error {
                        RxCBLogger.sharedInstance.log("Error: \(error.localizedDescription)")
                        return Observable.just(false)
                    }
                    
                    return Observable.just(true)
                }.do(onSubscribe: {
                    self.peripheral.discoverServices([service])
                })
                
    }
    
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadRSSISubject.onNext(RSSI.intValue)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let discoveredServices = peripheral.services ?? []
        let servicesData = (discoveredServices, error)
        RxCBLogger.sharedInstance.log("Discovered peripheral services: \(discoveredServices.description)")
        didDiscoverServicesSubject.onNext(servicesData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let discoveredChars = service.characteristics ?? []
        let characteristicsData = (discoveredChars, error)
        RxCBLogger.sharedInstance.log("Discovered peripheral services: \(discoveredChars.description)")
        didDiscoverCharacteristicsSubject.onNext(characteristicsData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
            guard let desc = characteristic.descriptors else { return }
            for des in desc {
//                des.setValue(<#T##value: Any?##Any?#>, forKey: <#T##String#>)
                print("BEGIN:SPAKA DESCRIPTOR========>\(des)")
//                self.peripheral.setNotifyValue(true, for: characteristic)
            }
    }
    
    /// Invoked when you retrieve a characteristic’s value, or when the peripheral notifies you the value has changed
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let valueData = (characteristic, error)
        if characteristic.value != nil {
            let value = characteristic.value?.subdata(in: Range(1...2)).withUnsafeBytes {$0.load(as: UInt8.self)}
            print("didUpdateValueFor Characteristic", characteristic, " value:", value ?? "No data 324")
        }
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
    
    private let peripheral: CBPeripheralType
    private let connectionState: Observable<ConnectionState>
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

extension GattError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return NSLocalizedString("No matching service found for connected peripheral.", comment: "GATT error")
        case .characteristicNotFound:
            return NSLocalizedString("No matching characteristic found for connected peripheral.", comment: "GATT error")
        case .notConnected:
            return NSLocalizedString("Not connected: cannot perform Gatt operations", comment: "GATT error")
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
