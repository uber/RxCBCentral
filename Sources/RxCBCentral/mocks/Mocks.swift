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
    public init(bluetoothCapability: Observable<BluetoothCapability> = PublishSubject(), enabled: Observable<Bool> = PublishSubject()) {
        self.bluetoothCapability = bluetoothCapability
        self.enabled = enabled
        _doneInit = true
    }
        
    private var bluetoothCapabilitySubjectKind = 0
    public var bluetoothCapabilitySubjectSetCallCount = 0
    public var bluetoothCapabilitySubject = PublishSubject<BluetoothCapability>() { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    public var bluetoothCapabilityReplaySubject = ReplaySubject<BluetoothCapability>.create(bufferSize: 1) { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    public var bluetoothCapabilityBehaviorSubject: BehaviorSubject<BluetoothCapability>! { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    public var bluetoothCapabilityRxSubject: Observable<BluetoothCapability>! { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    public var bluetoothCapability: Observable<BluetoothCapability> {
        get {
            if bluetoothCapabilitySubjectKind == 0 {
                return bluetoothCapabilitySubject
            } else if bluetoothCapabilitySubjectKind == 1 {
                return bluetoothCapabilityBehaviorSubject
            } else if bluetoothCapabilitySubjectKind == 2 {
                return bluetoothCapabilityReplaySubject
            } else {
                return bluetoothCapabilityRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<BluetoothCapability> {
                bluetoothCapabilitySubject = val
                bluetoothCapabilitySubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<BluetoothCapability> {
                bluetoothCapabilityBehaviorSubject = val
                bluetoothCapabilitySubjectKind = 1
            } else if let val = newValue as? ReplaySubject<BluetoothCapability> {
                bluetoothCapabilityReplaySubject = val
                bluetoothCapabilitySubjectKind = 2
            } else {
                bluetoothCapabilityRxSubject = newValue
                bluetoothCapabilitySubjectKind = 3
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
    public init(identifier: UUID = UUID(), state: CBPeripheralState = .disconnected) {
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

class CBCentralManagerTypeMock: CBCentralManagerType {

    private var _doneInit = false
    init(delegate: CBCentralManagerDelegate? = nil, isScanning: Bool = false, state: CBManagerState = .unknown) {
        self.delegate = delegate
        self.isScanning = isScanning
        self.state = state
        _doneInit = true
    }
        
    var delegateSetCallCount = 0
    var underlyingDelegate: CBCentralManagerDelegate? = nil
    var delegate: CBCentralManagerDelegate? {
        get { return underlyingDelegate }
        set {
            underlyingDelegate = newValue
            if _doneInit { delegateSetCallCount += 1 }
        }
    }
    
    var isScanningSetCallCount = 0
    var underlyingIsScanning: Bool = false
    var isScanning: Bool {
        get { return underlyingIsScanning }
        set {
            underlyingIsScanning = newValue
            if _doneInit { isScanningSetCallCount += 1 }
        }
    }
    
    var stateSetCallCount = 0
    var underlyingState: CBManagerState!
    var state: CBManagerState {
        get { return underlyingState }
        set {
            underlyingState = newValue
            if _doneInit { stateSetCallCount += 1 }
        }
    }
    
    var scanForPeripheralsCallCount = 0
    var scanForPeripheralsHandler: (([CBUUID]?, [String : Any]?) -> ())?
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)  {
        scanForPeripheralsCallCount += 1
    
        if let scanForPeripheralsHandler = scanForPeripheralsHandler {
            scanForPeripheralsHandler(serviceUUIDs, options)
        }
        
    }
    
    var stopScanCallCount = 0
    var stopScanHandler: (() -> ())?
    func stopScan()  {
        stopScanCallCount += 1
    
        if let stopScanHandler = stopScanHandler {
            stopScanHandler()
        }
        
    }
    
    var connectCallCount = 0
    var connectHandler: ((CBPeripheralType, ConnectionManagerOptions?) -> ())?
    func connect(_ peripheral: CBPeripheralType, options: ConnectionManagerOptions?)  {
        connectCallCount += 1
    
        if let connectHandler = connectHandler {
            connectHandler(peripheral, options)
        }
        
    }
    
    var cancelPeripheralConnectionCallCount = 0
    var cancelPeripheralConnectionHandler: ((CBPeripheralType) -> ())?
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType)  {
        cancelPeripheralConnectionCallCount += 1
    
        if let cancelPeripheralConnectionHandler = cancelPeripheralConnectionHandler {
            cancelPeripheralConnectionHandler(peripheral)
        }
        
    }
}

class RxCentralDelegateMock: NSObject, RxCentralDelegate {

    private var _doneInit = false
        override init() { _doneInit = true }
    init(bluetoothCapability: Observable<BluetoothCapability> = PublishSubject(), didDiscoverPeripheral: Observable<ScanData> = PublishSubject(), didConnectToPeripheral: Observable<CBPeripheralType> = PublishSubject(), didFailToConnect: Observable<(CBPeripheralType, Error?)> = PublishSubject(), didDisconnectPeripheral: Observable<(CBPeripheralType, Error?)> = PublishSubject()) {
        super.init()
        self.bluetoothCapability = bluetoothCapability
        self.didDiscoverPeripheral = didDiscoverPeripheral
        self.didConnectToPeripheral = didConnectToPeripheral
        self.didFailToConnect = didFailToConnect
        self.didDisconnectPeripheral = didDisconnectPeripheral
        _doneInit = true
    }
        
    private var bluetoothCapabilitySubjectKind = 0
    var bluetoothCapabilitySubjectSetCallCount = 0
    var bluetoothCapabilitySubject = PublishSubject<BluetoothCapability>() { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    var bluetoothCapabilityReplaySubject = ReplaySubject<BluetoothCapability>.create(bufferSize: 1) { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    var bluetoothCapabilityBehaviorSubject: BehaviorSubject<BluetoothCapability>! { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    var bluetoothCapabilityRxSubject: Observable<BluetoothCapability>! { didSet { if _doneInit { bluetoothCapabilitySubjectSetCallCount += 1 } } }
    var bluetoothCapability: Observable<BluetoothCapability> {
        get {
            if bluetoothCapabilitySubjectKind == 0 {
                return bluetoothCapabilitySubject
            } else if bluetoothCapabilitySubjectKind == 1 {
                return bluetoothCapabilityBehaviorSubject
            } else if bluetoothCapabilitySubjectKind == 2 {
                return bluetoothCapabilityReplaySubject
            } else {
                return bluetoothCapabilityRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<BluetoothCapability> {
                bluetoothCapabilitySubject = val
                bluetoothCapabilitySubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<BluetoothCapability> {
                bluetoothCapabilityBehaviorSubject = val
                bluetoothCapabilitySubjectKind = 1
            } else if let val = newValue as? ReplaySubject<BluetoothCapability> {
                bluetoothCapabilityReplaySubject = val
                bluetoothCapabilitySubjectKind = 2
            } else {
                bluetoothCapabilityRxSubject = newValue
                bluetoothCapabilitySubjectKind = 3
            }
        }
    }
    
    private var didDiscoverPeripheralSubjectKind = 0
    var didDiscoverPeripheralSubjectSetCallCount = 0
    var didDiscoverPeripheralSubject = PublishSubject<ScanData>() { didSet { if _doneInit { didDiscoverPeripheralSubjectSetCallCount += 1 } } }
    var didDiscoverPeripheralReplaySubject = ReplaySubject<ScanData>.create(bufferSize: 1) { didSet { if _doneInit { didDiscoverPeripheralSubjectSetCallCount += 1 } } }
    var didDiscoverPeripheralBehaviorSubject: BehaviorSubject<ScanData>! { didSet { if _doneInit { didDiscoverPeripheralSubjectSetCallCount += 1 } } }
    var didDiscoverPeripheralRxSubject: Observable<ScanData>! { didSet { if _doneInit { didDiscoverPeripheralSubjectSetCallCount += 1 } } }
    var didDiscoverPeripheral: Observable<ScanData> {
        get {
            if didDiscoverPeripheralSubjectKind == 0 {
                return didDiscoverPeripheralSubject
            } else if didDiscoverPeripheralSubjectKind == 1 {
                return didDiscoverPeripheralBehaviorSubject
            } else if didDiscoverPeripheralSubjectKind == 2 {
                return didDiscoverPeripheralReplaySubject
            } else {
                return didDiscoverPeripheralRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<ScanData> {
                didDiscoverPeripheralSubject = val
                didDiscoverPeripheralSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<ScanData> {
                didDiscoverPeripheralBehaviorSubject = val
                didDiscoverPeripheralSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<ScanData> {
                didDiscoverPeripheralReplaySubject = val
                didDiscoverPeripheralSubjectKind = 2
            } else {
                didDiscoverPeripheralRxSubject = newValue
                didDiscoverPeripheralSubjectKind = 3
            }
        }
    }
    
    private var didConnectToPeripheralSubjectKind = 0
    var didConnectToPeripheralSubjectSetCallCount = 0
    var didConnectToPeripheralSubject = PublishSubject<CBPeripheralType>() { didSet { if _doneInit { didConnectToPeripheralSubjectSetCallCount += 1 } } }
    var didConnectToPeripheralReplaySubject = ReplaySubject<CBPeripheralType>.create(bufferSize: 1) { didSet { if _doneInit { didConnectToPeripheralSubjectSetCallCount += 1 } } }
    var didConnectToPeripheralBehaviorSubject: BehaviorSubject<CBPeripheralType>! { didSet { if _doneInit { didConnectToPeripheralSubjectSetCallCount += 1 } } }
    var didConnectToPeripheralRxSubject: Observable<CBPeripheralType>! { didSet { if _doneInit { didConnectToPeripheralSubjectSetCallCount += 1 } } }
    var didConnectToPeripheral: Observable<CBPeripheralType> {
        get {
            if didConnectToPeripheralSubjectKind == 0 {
                return didConnectToPeripheralSubject
            } else if didConnectToPeripheralSubjectKind == 1 {
                return didConnectToPeripheralBehaviorSubject
            } else if didConnectToPeripheralSubjectKind == 2 {
                return didConnectToPeripheralReplaySubject
            } else {
                return didConnectToPeripheralRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<CBPeripheralType> {
                didConnectToPeripheralSubject = val
                didConnectToPeripheralSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<CBPeripheralType> {
                didConnectToPeripheralBehaviorSubject = val
                didConnectToPeripheralSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<CBPeripheralType> {
                didConnectToPeripheralReplaySubject = val
                didConnectToPeripheralSubjectKind = 2
            } else {
                didConnectToPeripheralRxSubject = newValue
                didConnectToPeripheralSubjectKind = 3
            }
        }
    }
    
    private var didFailToConnectSubjectKind = 0
    var didFailToConnectSubjectSetCallCount = 0
    var didFailToConnectSubject = PublishSubject<(CBPeripheralType, Error?)>() { didSet { if _doneInit { didFailToConnectSubjectSetCallCount += 1 } } }
    var didFailToConnectReplaySubject = ReplaySubject<(CBPeripheralType, Error?)>.create(bufferSize: 1) { didSet { if _doneInit { didFailToConnectSubjectSetCallCount += 1 } } }
    var didFailToConnectBehaviorSubject: BehaviorSubject<(CBPeripheralType, Error?)>! { didSet { if _doneInit { didFailToConnectSubjectSetCallCount += 1 } } }
    var didFailToConnectRxSubject: Observable<(CBPeripheralType, Error?)>! { didSet { if _doneInit { didFailToConnectSubjectSetCallCount += 1 } } }
    var didFailToConnect: Observable<(CBPeripheralType, Error?)> {
        get {
            if didFailToConnectSubjectKind == 0 {
                return didFailToConnectSubject
            } else if didFailToConnectSubjectKind == 1 {
                return didFailToConnectBehaviorSubject
            } else if didFailToConnectSubjectKind == 2 {
                return didFailToConnectReplaySubject
            } else {
                return didFailToConnectRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<(CBPeripheralType, Error?)> {
                didFailToConnectSubject = val
                didFailToConnectSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<(CBPeripheralType, Error?)> {
                didFailToConnectBehaviorSubject = val
                didFailToConnectSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<(CBPeripheralType, Error?)> {
                didFailToConnectReplaySubject = val
                didFailToConnectSubjectKind = 2
            } else {
                didFailToConnectRxSubject = newValue
                didFailToConnectSubjectKind = 3
            }
        }
    }
    
    private var didDisconnectPeripheralSubjectKind = 0
    var didDisconnectPeripheralSubjectSetCallCount = 0
    var didDisconnectPeripheralSubject = PublishSubject<(CBPeripheralType, Error?)>() { didSet { if _doneInit { didDisconnectPeripheralSubjectSetCallCount += 1 } } }
    var didDisconnectPeripheralReplaySubject = ReplaySubject<(CBPeripheralType, Error?)>.create(bufferSize: 1) { didSet { if _doneInit { didDisconnectPeripheralSubjectSetCallCount += 1 } } }
    var didDisconnectPeripheralBehaviorSubject: BehaviorSubject<(CBPeripheralType, Error?)>! { didSet { if _doneInit { didDisconnectPeripheralSubjectSetCallCount += 1 } } }
    var didDisconnectPeripheralRxSubject: Observable<(CBPeripheralType, Error?)>! { didSet { if _doneInit { didDisconnectPeripheralSubjectSetCallCount += 1 } } }
    var didDisconnectPeripheral: Observable<(CBPeripheralType, Error?)> {
        get {
            if didDisconnectPeripheralSubjectKind == 0 {
                return didDisconnectPeripheralSubject
            } else if didDisconnectPeripheralSubjectKind == 1 {
                return didDisconnectPeripheralBehaviorSubject
            } else if didDisconnectPeripheralSubjectKind == 2 {
                return didDisconnectPeripheralReplaySubject
            } else {
                return didDisconnectPeripheralRxSubject
            }
        }
        set {
            if let val = newValue as? PublishSubject<(CBPeripheralType, Error?)> {
                didDisconnectPeripheralSubject = val
                didDisconnectPeripheralSubjectKind = 0
            } else if let val = newValue as? BehaviorSubject<(CBPeripheralType, Error?)> {
                didDisconnectPeripheralBehaviorSubject = val
                didDisconnectPeripheralSubjectKind = 1
            } else if let val = newValue as? ReplaySubject<(CBPeripheralType, Error?)> {
                didDisconnectPeripheralReplaySubject = val
                didDisconnectPeripheralSubjectKind = 2
            } else {
                didDisconnectPeripheralRxSubject = newValue
                didDisconnectPeripheralSubjectKind = 3
            }
        }
    }
    
    var centralManagerDidUpdateStateCallCount = 0
    var centralManagerDidUpdateStateHandler: ((CBCentralManager) -> ())?
    func centralManagerDidUpdateState(_ central: CBCentralManager)  {
        centralManagerDidUpdateStateCallCount += 1
    
        if let centralManagerDidUpdateStateHandler = centralManagerDidUpdateStateHandler {
            centralManagerDidUpdateStateHandler(central)
        }
        
    }
}

public class GattOperationMock: GattOperation {

    private var _doneInit = false
        public init() { _doneInit = true }
    public init(result: Single<Element>) {
        self.result = result
        _doneInit = true
    }
        
    public var executeCallCount = 0
    public var executeHandler: ((RxPeripheral) -> ())?
    public func execute(with peripheral: RxPeripheral)  {
        executeCallCount += 1
    
        if let executeHandler = executeHandler {
            executeHandler(peripheral)
        }
        
    }
    public typealias Element = Any
    
    public var resultSetCallCount = 0
    var underlyingResult: Single<Element>!
    public var result: Single<Element> {
        get { return underlyingResult }
        set {
            underlyingResult = newValue
            if _doneInit { resultSetCallCount += 1 }
        }
    }
}

public class GattOperationExecutableMock: GattOperationExecutable {

    private var _doneInit = false
    
    public init() {

        _doneInit = true
    }
        
    public var executeCallCount = 0
    public var executeHandler: ((RxPeripheral) -> ())?
    public func execute(with peripheral: RxPeripheral)  {
        executeCallCount += 1
    
        if let executeHandler = executeHandler {
            executeHandler(peripheral)
        }
        
    }
}
