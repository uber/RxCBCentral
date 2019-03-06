# RxCBCentral

## Overview
WORK IN PROGRESS 

RxCBCentral is a reactive, interface-driven library used to integrate with Bluetooth LE peripherals.

For those tired of writing eerily similar, yet subtly different code for every Bluetooth LE peripheral integration, RxCBCentral provides a standardized, simple reactive paradigm for connecting to and communicating with peripherals from the central role.

Check out our detailed Wiki for designs and examples for all the capabilities of RxCBCentral.

## Integration steps

// TODO 
These are the steps that need to be taken to integrate the library in a new app.

2. `import RxCentralBLE`

3. Use classes to your heart's content.

## Usage

RxCBCentral makes Bluetooth connection and communication simple.

Scan and Connect:
```
let bluetoothDetector = BluetoothDetector(options: nil)
let connectionManager = ConnectionManager(bluetoothDetector: bluetoothDetector, queue: nil, options: nil)

// connects to the first device found with matching services and characteristics
let gattIO: Observable<GattIO> = 
    connectionManager
        .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: nil)
```

Scan, Connect, and Read:
```
connectionManager
    .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: scanMatcher)
    .read(service: serviceUUID, characteristic: characteristicUUID)
    .subscribe(onNext: { (data: Data?) in
        // do something with data
    })
    .disposed(by: disposeBag)
```

Scan, Connect, and Write:
```
guard let data = Data(base64Encoded: "A3V1") else { return }

connectionManager
    .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: scanMatcher)
    .write(service: serviceUUID, characteristic: characteristicUUID, data: data)
    .subscribe(onComplete: { (data: Data?) in
        // do something on complete
    })
    .disposed(by: disposeBag)
```

## Testing

This should describe how the object should be tested. For example, Portal has a separate `portal-test` module that includes a `PortalTestHelper` to register and clear objects with a test portal. AutoDispose provides a `TestScopeProvider` that can `create()` objects to be used during testing. Other libraries might have a `Foo` object that should be mocked or stubbed.

## Links
