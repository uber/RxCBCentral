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
    private var gattManager: GattManager!
    private let disposeBag = DisposeBag()
    
    private var isConnected = false {
        didSet {
            let title = isConnected ? "Disconnect" : "Connect"
            
            DispatchQueue.main.async {
                self.connectionButton.setTitle(title, for: .normal)
            }
        }
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var consoleTextView: UITextView!
    @IBOutlet weak var deviceNameTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothDetector = BluetoothDetector(options: nil)
        connectionManager = ConnectionManager(bluetoothDetector: bluetoothDetector, queue: nil, options: nil)
        gattManager = GattManager()
        
        subscribeToRxCBLogger()
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        guard !isConnected else {
            connectionManager.disconnectPeripheral()
            isConnected = false
            return
        }
        
        nameTextField.text = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        nameTextField.resignFirstResponder()
        
        var scanMatcher: ScanMatching? = nil
        
        if let deviceName = nameTextField.text, deviceName.isNotEmpty {
            scanMatcher = DeviceNameScanMatcher(deviceName: deviceName)
        }
        
        //let servicesToFind = [GattUUIDs.BATTERY_SVC_UUID]
        let beaconService = CBUUID(string: "C7971000-7942-4F36-8165-C71575A14A97")
        let beaconCharacteristic = CBUUID(string: "C7971001-7942-4F36-8165-C71575A14A97")
        let servicesToFind = [beaconService]
        
        // Two ways to connect to and read from a peripheral:
        
        // 1. Connect to a peripheral and immediately read. No queueing functionality - best for 1-time operations. Not ideal, but succinct.
//        connectionManager
//            .connectToPeripheral(with: servicesToFind, scanMatcher: scanMatcher)
//            .read(service: GattUUIDs.BATTERY_SVC_UUID, characteristic: GattUUIDs.BATTERY_LEVEL_UUID)
//            .subscribe(onNext: { (data: Data?) in
//                // do something with data
//                print(data?.description ?? "no data")
//            })
//            .disposed(by: disposeBag)
        
        
        // 2. Connect to a peripheral, optionally perform custom logic, and queue read operation (recommended)
        
        // Connect, inject gattIO into GattManager
        connectionManager
            .connectToPeripheral(with: servicesToFind, scanMatcher: scanMatcher)
            .subscribe(onNext: { (gattIO: GattIO) in
                // successfully connected, custom logic
                self.isConnected = true
                self.deviceNameTextView.text = gattIO.deviceName ?? "N/A"
                // ...
                
                // give the gattManager a GattIO to queue operations
                self.gattManager.gattIO = gattIO
            }, onError: { (error: Error) in
                // connection lost
                self.isConnected = false
            })
            .disposed(by: disposeBag)
        
        // create a read operation
        let readOp = Read(service: beaconService, characteristic: beaconCharacteristic, timeoutSeconds: 30)
        
        // or write operation
//        let data = "0x0".data(using: .utf8)!
//        let writeOp = Write(service: beaconService, characteristic: beaconCharacteristic, data: data, timeoutSeconds: 30)
        
        // queue the operation on the gattManager
        gattManager
            .queue(operation: readOp)
            .subscribe(onSuccess: { _ in
                // write successful
            }, onError: { (error) in
                self.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    private func consoleLog(_ text: String) {
        DispatchQueue.main.async {
            self.consoleTextView.text.append(contentsOf: "\n\n" + text)
            
            let range = NSRange(location: self.consoleTextView.text.count, length: 0)
            self.consoleTextView.scrollRangeToVisible(range)
        }
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

fileprivate class DeviceNameScanMatcher: ScanMatching {
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func accept(_ peripheral: CBPeripheral) -> Observable<CBPeripheral> {
        peripherals.insert(peripheral)
        
        return
            Observable.create { observer in
                // if we find a substring name match, return that peripheral
                for peripheral in self.peripherals {
                    if let name = peripheral.name?.lowercased(), name.contains(self.deviceName.lowercased()) {
                        observer.onNext(peripheral)
                    }
                }
                
                return Disposables.create()
            }
    }
    
    private let deviceName: String
    private var peripherals: Set<CBPeripheral> = []
}

extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}
