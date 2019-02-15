//
//  ViewController.swift
//  ExampleApp
//
//  Created by Joseph Soultanis on 1/10/19.
//  Copyright © 2019 Joseph Soultanis. All rights reserved.
//

import CoreBluetooth
import RxCBCentral
import RxSwift
import UIKit

class ViewController: UIViewController {
    
    private var bluetoothDetector: BluetoothDetector!
    private var connectionManager: ConnectionManager!
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var consoleTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothDetector = CoreBluetoothDetector(options: nil)
        connectionManager = CoreConnectionManager(bluetoothDetector: bluetoothDetector, queue: nil, options: nil)
        
        subscribeToRxCBLogger()
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        nameTextField.resignFirstResponder()
        
        var scanMatcher: ScanMatcher? = nil
        
        if let deviceName = nameTextField.text, deviceName.isNotEmpty {
            scanMatcher = DeviceNameScanMatcher(deviceName: deviceName)
        }
        
        let servicesToFind = [GattUUIDs.BATTERY_SVC_UUID, GattUUIDs.DIS_SVC_UUID, GattUUIDs.GAP_SVC_UUID]
        
        // Two ways to connect to and read from a peripheral:
        
        // 1. Connect to a peripheral and immediately read
        connectionManager
            .connectToPeripheral(with: servicesToFind, scanMatcher: scanMatcher)
            .read(service: GattUUIDs.BATTERY_SVC_UUID, characteristic: GattUUIDs.BATTERY_LEVEL_UUID)
            .subscribe(onNext: { (data: Data?) in
                // do something with data
                print(data?.description ?? "no data")
            })
            .disposed(by: disposeBag)
        
        
        // 2. Connect to a peripheral and perform custom logic before reading
//        connectionManager
//            .connectToPeripheral(with: [serviceUUID, characteristicUUID], scanMatcher: scanMatcher)
//            .flatMap { (gattIO) -> Single<Data?> in
//                let deviceName = gattIO.deviceName ?? "no device name"
//                self.consoleLog(text: "Connected to \(deviceName)!")
//
//                return gattIO.read(service: serviceUUID, characteristic: characteristicUUID)
//            }
//            .subscribe(onNext: { (data: Data?) in
//                if let data = data {
//                    let dataString = data.hexEncodedString()
//                    self.consoleLog(text: "Read: \(dataString)")
//                } else {
//                    self.consoleLog(text: "Read: No data found")
//                }
//            }, onError: { (error) in
//                self.consoleLog(text: "Error: \(error.localizedDescription)")
//            })
//            .disposed(by: disposeBag)
    }
    
    private func consoleLog(_ text: String) {
        consoleTextView.text.append(contentsOf: "\n\n" + text)
    }
    
    private func subscribeToRxCBLogger() {
        RxCBLogger.sharedInstance
            .read()
            .subscribe(onNext: { (log: String) in
                self.consoleLog(log)
            })
            .disposed(by: disposeBag)
    }
}

fileprivate class DeviceNameScanMatcher: ScanMatcher {
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func accept(_ peripheral: CBPeripheral) -> Observable<CBPeripheral> {
        peripherals.insert(peripheral)
        
        return
            Observable.create { observer in
                // if we find a substring name match, return that peripheral
                for peripheral in self.peripherals {
                    if let name = peripheral.name, name.contains(self.deviceName) {
                        observer.onNext(peripheral)
                    }
                }
                
                return Disposables.create()
            }
    }
    
    private let deviceName: String
    private var peripherals: Set<CBPeripheral> = []
}

