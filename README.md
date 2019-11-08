# RxCBCentral

## Overview
WORK IN PROGRESS 

RxCBCentral is a reactive, interface-driven library used to integrate with Bluetooth LE peripherals.

For those tired of writing eerily similar, yet subtly different code for every Bluetooth LE peripheral integration, RxCBCentral provides a standardized, simple reactive paradigm for connecting to and communicating with peripherals from the central role.

Check out our detailed [Wiki](https://github.com/uber/RxCBCentral/wiki) for designs and examples for all the capabilities of RxCBCentral.

## Integration steps

// TODO : Add Carthage details

## Usage

RxCBCentral makes Bluetooth connection and communication simple.

Scan, Connect and Disconnect:
```
let peripheralManager = RxPeripheralManager()
let connectionManager = ConnectionManager(rxPeripheralManager: peripheralManager, queue: nil, options: nil)

// connects to the first device found with matching services and characteristics
let connectionDisposable = 
    connectionManager
    .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: nil)
    .subscribe(onNext: { (peripheral: RxPeripheral) -> in
        // IMPORTANT: inject the RxPeripheral into the manager after connecting
        self.peripheralManager.rxPeripheral = peripheral
    })
    
// disconnect
connectionDisposable.dispose()
```

Scan, Connect, and Read:
```
let scanMatcher = RssiScanMatcher()
let peripheralManager = RxPeripheralManager()
let connectionManager = ConnectionManager(rxPeripheralManager: peripheralManager, queue: nil, options: nil)

connectionManager
    .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: scanMatcher)  // connect to closest peripheral using RSSI
    .flatMapLatest { (peripheral: RxPeripheral) -> Data in
        // IMPORTANT: inject the RxPeripheral into the manager after connecting
        self.peripheralManager.rxPeripheral = peripheral
        
        return self.peripheralManager.queue(operation: Read(service: serviceUUID, characteristic: characteristicUUID))
    }
    .subscribe(onNext: { (data: Data?) in
        // do something with read BLE data
    })
    .disposed(by: disposeBag)
```

Scan, Connect, and Write:
```
guard let data = Data(base64Encoded: "A3V1") else { return }

connectionManager
    .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: nil)
    .flatMapLatest { (peripheral: RxPeripheral) -> Completable in
        // IMPORTANT: inject the RxPeripheral into the manager after connecting
        self.peripheralManager.rxPeripheral = peripheral
        
        return self.peripheralManager.queue(operation: Write(service: serviceUUID, characteristic: characteristicUUID, data: data))
    }
    .subscribe(onCompleted: {
        // do something on write completion
    })
    .disposed(by: disposeBag)
```

After connecting, you can use the `RxPeripheralManager` to queue read and write BLE operatons, as well as setting up subscriptions to notifications for a particular characteristic.

Subscribe for Notify Events:
```
let peripheralManager = RxPeripheralManager()

peripheralManager
    .isConnected
    .filter { $0 } // wait until we're connected before performing BLE operations
    .flatMapLatest { _ -> Observable<Data> in
        // listen for Heart Rate Measurement events
        return self.peripheralManager.receiveNotifications(for: CBUUID(string: "2A37"))
    }
    .subscribe(onNext: { data in
        // do something with Heart Rate Measurement data
    })
    .disposed(by: disposeBag)
```

## Sample App

See the Example app in this repo for additional usages of the library, and visualize low level BLE operations happening in realtime (scanning, discovery events, connecting, etc.).
