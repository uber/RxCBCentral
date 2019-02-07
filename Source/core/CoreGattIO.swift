
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

public enum GattIOError: Error {
    case serviceNotFound
    case characteristicNotFound
}

public class CoreGattIO: NSObject, GattIO, CBPeripheralDelegate {
    
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
    
    public func maxWriteLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
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
                .do(onNext: { (matchingCharacteristic: CBCharacteristic?, error: Error?) in
                    if let matchingCharacteristic = matchingCharacteristic, error == nil {
                        self.peripheral.readValue(for: matchingCharacteristic)
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?)  -> Observable<(Data?, Error?)> in
                    guard let _ = matchingCharacteristic else {
                        return Observable.error(GattIOError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        return Observable.error(error)
                    }
                    
                    return self.didReadFromCharacteristicSubject.asObservable()
                }
                .map { (readData: Data?, error: Error?) -> Data? in
                    // how to handle Read error? Filter nil or no?
                    return readData
                }
                .take(1)
                .asSingle()
                .do(onSubscribe: {
                    // add a check if we've already discovered valid services / charac
                    self.peripheral.discoverServices([service])
                })
        
        return sharedReadDataObservable
    }
    
    public func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        
        let sharedWriteCompletable: Completable =
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
                .do(onNext: { (matchingCharacteristic: CBCharacteristic?, error: Error?) in
                    if let matchingCharacteristic = matchingCharacteristic, error == nil {
                        let CBCharacteristicPropertyWrite: UInt = 0x08
                        let writeType = (matchingCharacteristic.properties.rawValue & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite ? CBCharacteristicWriteType.withResponse : CBCharacteristicWriteType.withoutResponse
                        
                        // let CB give an error if property isn't writable
                        self.peripheral.writeValue(data, for: matchingCharacteristic, type: writeType)
                    }
                })
                .flatMapLatest { (matchingCharacteristic: CBCharacteristic?, error: Error?) -> Observable<Error?> in
                    guard let _ = matchingCharacteristic else {
                        return Observable.error(GattIOError.characteristicNotFound)
                    }
                    
                    if let error = error {
                        return Observable.error(error)
                    }
                    
                    return self.didWriteToCharacteristicSubject.asObservable()
                }
                .take(1)
                .flatMapLatest { (error: Error?) -> Completable in
                    if let error = error {
                        return Observable.error(error).asCompletable()
                    }
                    return Observable.empty().asCompletable()
                }
                .take(1)
                .asCompletable()
                .do(onSubscribe: {
                    self.peripheral.discoverServices([service])
                })
        
        
        return sharedWriteCompletable
    }

    public func registerForNotification(service: CBUUID, characteristic: CBUUID) -> Completable {
        return Observable.empty().asCompletable()
    }

    public func process(data: Data) -> Data {
        return Data()
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
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let readData = (characteristic.value, error)
        didReadFromCharacteristicSubject.onNext(readData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        didWriteToCharacteristicSubject.onNext(error)
    }
    
    // MARK: - Private
    
    private let peripheral: CBPeripheral
    private let connectionState: Observable<ConnectionManagerState>
    
    // MARK: - Delegate Subjects
    
    private let didReadRSSISubject = PublishSubject<Int>()
    private let didDiscoverServicesSubject = PublishSubject<([CBService], Error?)>()
    private let didDiscoverCharacteristicsSubject = PublishSubject<([CBCharacteristic], Error?)>()
    private let didReadFromCharacteristicSubject = PublishSubject<(Data?, Error?)>()
    private let didWriteToCharacteristicSubject = PublishSubject<Error?>()
}
