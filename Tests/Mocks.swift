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
import Foundation
import RxSwift
import RxCBCentral

public class CentralScannerMock: CentralScanner {

    private var _doneInit = false
    
    public init() {

        _doneInit = true
    }
        
    public var scanCallCount = 0
    public var scanHandler: (([CBUUID]?, ScanMatching?, ScanOptions?) -> (Observable<ScanData>))?
    public func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<ScanData> {
        scanCallCount += 1
    
        if let scanHandler = scanHandler {
            return scanHandler(services, scanMatcher, options)
        }
        return Observable.empty()
    }
    
    public var scanForCallCount = 0
    public var scanForHandler: (([CBUUID]?, ScanMatching?, ScanOptions?, RxTimeInterval) -> (Observable<ScanData>))?
    public func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?, scanTimeout: RxTimeInterval) -> Observable<ScanData> {
        scanForCallCount += 1
    
        if let scanForHandler = scanForHandler {
            return scanForHandler(services, scanMatcher, options, scanTimeout)
        }
        return Observable.empty()
    }
    
    public var stopScanCallCount = 0
    public var stopScanHandler: (() -> ())?
    public func stopScan()  {
        stopScanCallCount += 1
    
        if let stopScanHandler = stopScanHandler {
            stopScanHandler()
        }
        
    }
}

public class ConnectionManagerTypeMock: ConnectionManagerType {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(connectionState: Observable<ConnectionState> = PublishSubject()) {
        self.connectionState = connectionState
        _doneInit = true
    }
        
    private var connectionStateSubjectKind = 0
    public var connectionStateSubjectSetCallCount = 0
    public var connectionStateSubject = PublishSubject<ConnectionState>() { didSet { if _doneInit { connectionStateSubjectSetCallCount += 1 } } }
    public var connectionStateReplaySubject = ReplaySubject<ConnectionState>.create(bufferSize: 1) { didSet { if _doneInit { connectionStateSubjectSetCallCount += 1 } } }
    public var connectionStateBehaviorSubject: BehaviorSubject<ConnectionState>! { didSet { if _doneInit { connectionStateSubjectSetCallCount += 1 } } }
    public var connectionStateRxSubject: Observable<ConnectionState>! { didSet { if _doneInit { connectionStateSubjectSetCallCount += 1 } } }
    public var connectionState: Observable<ConnectionState> {
        get {
            if connectionStateSubjectKind == 0 {
                return connectionStateSubject
            } else if connectionStateSubjectKind == 1 {
                return connectionStateBehaviorSubject
            } else if connectionStateSubjectKind == 2 {
                return connectionStateReplaySubject
            } else {
                return connectionStateRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<ConnectionState> {
                connectionStateSubject = val
                connectionStateSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<ConnectionState> {
                connectionStateBehaviorSubject = val
                connectionStateSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<ConnectionState> {
                connectionStateReplaySubject = val
                connectionStateSubjectKind = 2
            } else {
                connectionStateRxSubject = newValue
                connectionStateSubjectKind = 3
            }
        }
    }
    
    public var scanCallCount = 0
    public var scanHandler: (([CBUUID]?, ScanMatching?, ScanOptions?) -> (Observable<ScanData>))?
    public func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<ScanData> {
        scanCallCount += 1
    
        if let scanHandler = scanHandler {
            return scanHandler(services, scanMatcher, options)
        }
        return Observable.empty()
    }
    
    public var connectToPeripheralCallCount = 0
    public var connectToPeripheralHandler: (([CBUUID]?, ScanMatching?, ScanOptions?) -> (Observable<RxPeripheral>))?
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?) -> Observable<RxPeripheral> {
        connectToPeripheralCallCount += 1
    
        if let connectToPeripheralHandler = connectToPeripheralHandler {
            return connectToPeripheralHandler(services, scanMatcher, options)
        }
        return Observable.empty()
    }
    
    public var scanForCallCount = 0
    public var scanForHandler: (([CBUUID]?, ScanMatching?, ScanOptions?, RxTimeInterval) -> (Observable<ScanData>))?
    public func scan(for services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?, scanTimeout: RxTimeInterval) -> Observable<ScanData> {
        scanForCallCount += 1
    
        if let scanForHandler = scanForHandler {
            return scanForHandler(services, scanMatcher, options, scanTimeout)
        }
        return Observable.empty()
    }
    
    public var connectToPeripheralWithCallCount = 0
    public var connectToPeripheralWithHandler: (([CBUUID]?, ScanMatching?, ScanOptions?, RxTimeInterval) -> (Observable<RxPeripheral>))?
    public func connectToPeripheral(with services: [CBUUID]?, scanMatcher: ScanMatching?, options: ScanOptions?, scanTimeout: RxTimeInterval) -> Observable<RxPeripheral> {
        connectToPeripheralWithCallCount += 1
    
        if let connectToPeripheralWithHandler = connectToPeripheralWithHandler {
            return connectToPeripheralWithHandler(services, scanMatcher, options, scanTimeout)
        }
        return Observable.empty()
    }
    
    public var stopScanCallCount = 0
    public var stopScanHandler: (() -> ())?
    public func stopScan()  {
        stopScanCallCount += 1
    
        if let stopScanHandler = stopScanHandler {
            stopScanHandler()
        }
        
    }
}

public class BluetoothDetectorTypeMock: BluetoothDetectorType {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(capability: Observable<BluetoothCapability> = PublishSubject(), enabled: Observable<Bool> = PublishSubject()) {
        self.capability = capability
        self.enabled = enabled
        _doneInit = true
    }
        
    private var capabilitySubjectKind = 0
    public var capabilitySubjectSetCallCount = 0
    public var capabilitySubject = PublishSubject<BluetoothCapability>() { didSet { if _doneInit { capabilitySubjectSetCallCount += 1 } } }
    public var capabilityReplaySubject = ReplaySubject<BluetoothCapability>.create(bufferSize: 1) { didSet { if _doneInit { capabilitySubjectSetCallCount += 1 } } }
    public var capabilityBehaviorSubject: BehaviorSubject<BluetoothCapability>! { didSet { if _doneInit { capabilitySubjectSetCallCount += 1 } } }
    public var capabilityRxSubject: Observable<BluetoothCapability>! { didSet { if _doneInit { capabilitySubjectSetCallCount += 1 } } }
    public var capability: Observable<BluetoothCapability> {
        get {
            if capabilitySubjectKind == 0 {
                return capabilitySubject
            } else if capabilitySubjectKind == 1 {
                return capabilityBehaviorSubject
            } else if capabilitySubjectKind == 2 {
                return capabilityReplaySubject
            } else {
                return capabilityRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<BluetoothCapability> {
                capabilitySubject = val
                capabilitySubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<BluetoothCapability> {
                capabilityBehaviorSubject = val
                capabilitySubjectKind = 1
            } else if let val = newValue as? ReplaySubject<BluetoothCapability> {
                capabilityReplaySubject = val
                capabilitySubjectKind = 2
            } else {
                capabilityRxSubject = newValue
                capabilitySubjectKind = 3
            }
        }
    }
    
    private var enabledSubjectKind = 0
    public var enabledSubjectSetCallCount = 0
    public var enabledSubject = PublishSubject<Bool>() { didSet { if _doneInit { enabledSubjectSetCallCount += 1 } } }
    public var enabledReplaySubject = ReplaySubject<Bool>.create(bufferSize: 1) { didSet { if _doneInit { enabledSubjectSetCallCount += 1 } } }
    public var enabledBehaviorSubject: BehaviorSubject<Bool>! { didSet { if _doneInit { enabledSubjectSetCallCount += 1 } } }
    public var enabledRxSubject: Observable<Bool>! { didSet { if _doneInit { enabledSubjectSetCallCount += 1 } } }
    public var enabled: Observable<Bool> {
        get {
            if enabledSubjectKind == 0 {
                return enabledSubject
            } else if enabledSubjectKind == 1 {
                return enabledBehaviorSubject
            } else if enabledSubjectKind == 2 {
                return enabledReplaySubject
            } else {
                return enabledRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<Bool> {
                enabledSubject = val
                enabledSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<Bool> {
                enabledBehaviorSubject = val
                enabledSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<Bool> {
                enabledReplaySubject = val
                enabledSubjectKind = 2
            } else {
                enabledRxSubject = newValue
                enabledSubjectKind = 3
            }
        }
    }
}

public class CBPeripheralTypeMock: CBPeripheralType {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(identifier: UUID = UUID(), state: CBPeripheralState) {
        self.identifier = identifier
        self.state = state
        _doneInit = true
    }
        
    public var delegateSetCallCount = 0
    var underlyingDelegate: CBPeripheralDelegate? = nil
    public var delegate: CBPeripheralDelegate? {
        get { return underlyingDelegate }
        set {
            underlyingDelegate = newValue
            if _doneInit { delegateSetCallCount += 1 }
        }
    }
    
    public var nameSetCallCount = 0
    var underlyingName: String? = nil
    public var name: String? {
        get { return underlyingName }
        set {
            underlyingName = newValue
            if _doneInit { nameSetCallCount += 1 }
        }
    }
    
    public var identifierSetCallCount = 0
    var underlyingIdentifier: UUID = UUID()
    public var identifier: UUID {
        get { return underlyingIdentifier }
        set {
            underlyingIdentifier = newValue
            if _doneInit { identifierSetCallCount += 1 }
        }
    }
    
    public var stateSetCallCount = 0
    var underlyingState: CBPeripheralState!
    public var state: CBPeripheralState {
        get { return underlyingState }
        set {
            underlyingState = newValue
            if _doneInit { stateSetCallCount += 1 }
        }
    }
    
    public var readRSSICallCount = 0
    public var readRSSIHandler: (() -> ())?
    public func readRSSI()  {
        readRSSICallCount += 1
    
        if let readRSSIHandler = readRSSIHandler {
            readRSSIHandler()
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
            discoverServicesHandler(serviceUUIDs)
        }
        
    }
    
    public var discoverCharacteristicsCallCount = 0
    public var discoverCharacteristicsHandler: (([CBUUID]?, CBService) -> ())?
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)  {
        discoverCharacteristicsCallCount += 1
    
        if let discoverCharacteristicsHandler = discoverCharacteristicsHandler {
            discoverCharacteristicsHandler(characteristicUUIDs, service)
        }
        
    }
    
    public var readValueCallCount = 0
    public var readValueHandler: ((CBCharacteristic) -> ())?
    public func readValue(for characteristic: CBCharacteristic)  {
        readValueCallCount += 1
    
        if let readValueHandler = readValueHandler {
            readValueHandler(characteristic)
        }
        
    }
    
    public var writeValueCallCount = 0
    public var writeValueHandler: ((Data, CBCharacteristic, CBCharacteristicWriteType) -> ())?
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)  {
        writeValueCallCount += 1
    
        if let writeValueHandler = writeValueHandler {
            writeValueHandler(data, characteristic, type)
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


public class RxPeripheralManagerTypeMock: RxPeripheralManagerType {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(isConnected: Observable<Bool> = PublishSubject()) {
        self.isConnected = isConnected
        _doneInit = true
    }
        
    public var rxPeripheralSetCallCount = 0
    var underlyingRxPeripheral: RxPeripheral? = nil
    public var rxPeripheral: RxPeripheral? {
        get { return underlyingRxPeripheral }
        set {
            underlyingRxPeripheral = newValue
            if _doneInit { rxPeripheralSetCallCount += 1 }
        }
    }
    
    private var isConnectedSubjectKind = 0
    public var isConnectedSubjectSetCallCount = 0
    public var isConnectedSubject = PublishSubject<Bool>() { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedReplaySubject = ReplaySubject<Bool>.create(bufferSize: 1) { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedBehaviorSubject: BehaviorSubject<Bool>! { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedRxSubject: Observable<Bool>! { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnected: Observable<Bool> {
        get {
            if isConnectedSubjectKind == 0 {
                return isConnectedSubject
            } else if isConnectedSubjectKind == 1 {
                return isConnectedBehaviorSubject
            } else if isConnectedSubjectKind == 2 {
                return isConnectedReplaySubject
            } else {
                return isConnectedRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<Bool> {
                isConnectedSubject = val
                isConnectedSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<Bool> {
                isConnectedBehaviorSubject = val
                isConnectedSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<Bool> {
                isConnectedReplaySubject = val
                isConnectedSubjectKind = 2
            } else {
                isConnectedRxSubject = newValue
                isConnectedSubjectKind = 3
            }
        }
    }
    
    public var queueCallCount = 0
    public var queueHandler: ((Any) -> (Any))?
    public func queue<O: GattOperation>(operation: O) -> Single<O.Element> {
        queueCallCount += 1
    
        if let queueHandler = queueHandler {
            return queueHandler(operation) as! Single<O.Element>
        }
        fatalError("queueHandler returns can't have a default value thus its handler must be set")
    }
    
    public var receiveNotificationsCallCount = 0
    public var receiveNotificationsHandler: ((CBUUID) -> (Observable<Data>))?
    public func receiveNotifications(for characteristic: CBUUID) -> Observable<Data> {
        receiveNotificationsCallCount += 1
    
        if let receiveNotificationsHandler = receiveNotificationsHandler {
            return receiveNotificationsHandler(characteristic)
        }
        return Observable.empty()
    }
}

public class RxPeripheralMock: RxPeripheral {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(isConnected: Observable<Bool> = PublishSubject(), maxWriteLength: Int = 0) {
        self.isConnected = isConnected
        self.maxWriteLength = maxWriteLength
        _doneInit = true
    }
        
    private var isConnectedSubjectKind = 0
    public var isConnectedSubjectSetCallCount = 0
    public var isConnectedSubject = PublishSubject<Bool>() { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedReplaySubject = ReplaySubject<Bool>.create(bufferSize: 1) { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedBehaviorSubject: BehaviorSubject<Bool>! { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnectedRxSubject: Observable<Bool>! { didSet { if _doneInit { isConnectedSubjectSetCallCount += 1 } } }
    public var isConnected: Observable<Bool> {
        get {
            if isConnectedSubjectKind == 0 {
                return isConnectedSubject
            } else if isConnectedSubjectKind == 1 {
                return isConnectedBehaviorSubject
            } else if isConnectedSubjectKind == 2 {
                return isConnectedReplaySubject
            } else {
                return isConnectedRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<Bool> {
                isConnectedSubject = val
                isConnectedSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<Bool> {
                isConnectedBehaviorSubject = val
                isConnectedSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<Bool> {
                isConnectedReplaySubject = val
                isConnectedSubjectKind = 2
            } else {
                isConnectedRxSubject = newValue
                isConnectedSubjectKind = 3
            }
        }
    }
    
    public var deviceNameSetCallCount = 0
    var underlyingDeviceName: String? = nil
    public var deviceName: String? {
        get { return underlyingDeviceName }
        set {
            underlyingDeviceName = newValue
            if _doneInit { deviceNameSetCallCount += 1 }
        }
    }
    
    public var maxWriteLengthSetCallCount = 0
    var underlyingMaxWriteLength: Int = 0
    public var maxWriteLength: Int {
        get { return underlyingMaxWriteLength }
        set {
            underlyingMaxWriteLength = newValue
            if _doneInit { maxWriteLengthSetCallCount += 1 }
        }
    }
    
    public var readRSSICallCount = 0
    public var readRSSIHandler: (() -> (Single<Int>))?
    public func readRSSI() -> Single<Int> {
        readRSSICallCount += 1
    
        if let readRSSIHandler = readRSSIHandler {
            return readRSSIHandler()
        }
        fatalError("readRSSIHandler returns can't have a default value thus its handler must be set")
    }
    
    public var readCallCount = 0
    public var readHandler: ((CBUUID, CBUUID) -> (Single<Data?>))?
    public func read(service: CBUUID, characteristic: CBUUID) -> Single<Data?> {
        readCallCount += 1
    
        if let readHandler = readHandler {
            return readHandler(service, characteristic)
        }
        fatalError("readHandler returns can't have a default value thus its handler must be set")
    }
    
    public var writeCallCount = 0
    public var writeHandler: ((CBUUID, CBUUID, Data) -> (Completable))?
    public func write(service: CBUUID, characteristic: CBUUID, data: Data) -> Completable {
        writeCallCount += 1
    
        if let writeHandler = writeHandler {
            return writeHandler(service, characteristic, data)
        }
        fatalError("writeHandler returns can't have a default value thus its handler must be set")
    }
    
    public var registerForNotificationCallCount = 0
    public var registerForNotificationHandler: ((CBUUID, CBUUID, Preprocessor?) -> (Completable))?
    public func registerForNotification(service: CBUUID, characteristic: CBUUID, preprocessor: Preprocessor?) -> Completable {
        registerForNotificationCallCount += 1
    
        if let registerForNotificationHandler = registerForNotificationHandler {
            return registerForNotificationHandler(service, characteristic, preprocessor)
        }
        fatalError("registerForNotificationHandler returns can't have a default value thus its handler must be set")
    }
    
    public var notificationDataCallCount = 0
    public var notificationDataHandler: ((CBUUID) -> (Observable<Data>))?
    public func notificationData(for characteristic: CBUUID) -> Observable<Data> {
        notificationDataCallCount += 1
    
        if let notificationDataHandler = notificationDataHandler {
            return notificationDataHandler(characteristic)
        }
        return Observable.empty()
    }
}
