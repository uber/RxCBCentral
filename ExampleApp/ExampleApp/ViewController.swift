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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        bluetoothDetector = CoreBluetoothDetector(options: nil)
        connectionManager = CoreConnectionManager(bluetoothDetector: bluetoothDetector, queue: nil, options: nil)
    }

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var consoleTextView: UITextView!
    
    @IBAction func didTapConnect(_ sender: Any) {
        nameTextField.resignFirstResponder()
        
//        let batteryService = CBUUID(string: "0x180F")
//        let currentTimeService = CBUUID(string: "0x1805")
//        let deviceInformationService = CBUUID(string: "0x180A")
//        let beaconServices = [batteryService, currentTimeService, deviceInformationService]
        
        var scanMatcher: ScanMatcher? = nil
        
        if let deviceName = nameTextField.text, deviceName.isNotEmpty {
            scanMatcher = DeviceNameScanMatcher(deviceName: deviceName)
        }
        
        let serviceUUID = CBUUID(string: "0x180A")
        let characteristicUUID = CBUUID(string: "0x2A29")
        
        disposable =
            connectionManager
                .connectToPeripheral(with: nil, scanMatcher: scanMatcher)
                .flatMap { (gattIO) -> Single<Data?> in
                    let deviceName = gattIO.deviceName ?? "no device name"
                    self.consoleLog(text: "Connected to \(deviceName)!")
                    
                    return gattIO.read(service: serviceUUID, characteristic: characteristicUUID)
                }
                .subscribe(onNext: { (data: Data?) in
                    if let data = data {
                        let dataString = data.hexEncodedString()
                        self.consoleLog(text: "Read: \(dataString)")
                    } else {
                        self.consoleLog(text: "Read: No data found")
                    }
                }, onError: { (error) in
                    self.consoleLog(text: "Error: \(error.localizedDescription)")
                })
        
        
        
    }
    
    private func consoleLog(text: String) {
        consoleTextView.text.append(contentsOf: "\n" + text)
    }
    
    private func showConnectionAlert() {
        // create the alert
        let alert = UIAlertController(title: "Invalid Name", message: "No peripheral matches that name. Please enter a valid name.", preferredStyle: UIAlertController.Style.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    private var disposable: Disposable? = nil
    
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


extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}

