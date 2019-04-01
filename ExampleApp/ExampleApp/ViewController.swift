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
    private var gattIO: GattIO? = nil
    
    private var isConnected = false {
        didSet {
            let title = isConnected ? "Disconnect" : "Connect"
            
            DispatchQueue.main.async {
                self.connectionButton.setTitle(title, for: .normal)
                self.gapButton.isEnabled = self.isConnected
                self.batteryButton.isEnabled = self.isConnected
                self.disButton.isEnabled = self.isConnected
                self.mtuButton.isEnabled = self.isConnected
                
                if !self.isConnected {
                    self.deviceNameTextView.text = "none"
                }
            }
        }
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var consoleTextView: UITextView!
    @IBOutlet weak var deviceNameTextView: UITextView!
    
    @IBOutlet weak var gapButton: UIButton!
    @IBOutlet weak var batteryButton: UIButton!
    @IBOutlet weak var disButton: UIButton!
    @IBOutlet weak var mtuButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothDetector = BluetoothDetector(options: nil)
        connectionManager = ConnectionManager(bluetoothDetector: bluetoothDetector, queue: nil, options: nil)
        gattManager = GattManager()
        
        subscribeToRxCBLogger()
        
        isConnected = false
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
            .connectToPeripheral(with: nil, scanMatcher: scanMatcher)
            .subscribe(onNext: { (gattIO: GattIO) in
                // successfully connected, custom logic
                self.isConnected = true
                self.deviceNameTextView.text = gattIO.deviceName ?? "N/A"
                self.gattIO = gattIO
                // ...
                
                // give the gattManager a GattIO to queue operations
                self.gattManager.gattIO = gattIO
            }, onError: { (error: Error) in
                // connection lost
                self.isConnected = false
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapGAPButton(_ sender: Any) {
        // create a read operation
        let read = Read(service: GattUUIDs.GAP_SVC_UUID, characteristic: GattUUIDs.GAP_DEVICE_NAME_UUID, timeoutSeconds: 30)
        
        // queue the operation on the gattManager
        gattManager
            .queue(operation: read)
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { (error) in
                self.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapBatteryButton(_ sender: Any) {
        let read = Read(service: GattUUIDs.BATTERY_SVC_UUID, characteristic: GattUUIDs.BATTERY_LEVEL_UUID, timeoutSeconds: 30)
        gattManager
            .queue(operation: read)
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { (error) in
                self.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapDISButton(_ sender: Any) {
        let read = Read(service: GattUUIDs.DIS_SVC_UUID, characteristic: GattUUIDs.DIS_MFG_NAME_UUID, timeoutSeconds: 30)
        gattManager
            .queue(operation: read)
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { (error) in
                self.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapMTUButton(_ sender: Any) {
        if let mtu = gattIO?.maxWriteLength {
            consoleLog("MTU: \(mtu)")
        } else {
            consoleLog("MTU: none")
        }
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
}

fileprivate class DeviceNameScanMatcher: ScanMatching {
    
    var matchedPeripheral: Observable<CBPeripheral> {
        return peripheralSequence
            .filter { (peripheral: CBPeripheral) -> Bool in
                guard let name = peripheral.name?.lowercased() else { return false }
              
                return name.contains(self.deviceName.lowercased())
            }
    }
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func accept(_ scanData: ScanData) {
        peripheralSequence.onNext(scanData.peripheral)
    }
    
    private let deviceName: String
    private let peripheralSequence = ReplaySubject<CBPeripheral>.create(bufferSize: 1)
}

extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}
