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
import RxCBCentral
import RxSwift
import UIKit

class ViewController: UIViewController {
    
    private var bluetoothDetector: BluetoothDetectorType!
    private var connectionManager: ConnectionManager!
    private var peripheralManager: RxPeripheralManagerType!
    private let disposeBag = DisposeBag()
    private var connectionDisposable: Disposable? = nil
    
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
        bluetoothDetector = BluetoothDetector(options: BluetoothDetectorOptions(showPowerAlert: false))
        peripheralManager = RxPeripheralManager()
        connectionManager = ConnectionManager(peripheralGattManager: peripheralManager)
        
        subscribeToRxCBLogger()
        
        isConnected = false
        
        peripheralManager.isConnected
            .subscribe(onNext: { (connected: Bool) in
                print("isConnected: \(connected)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapConnect(_ sender: Any) {
        guard !isConnected else {
            connectionDisposable?.dispose()
            isConnected = false
            return
        }
        
        nameTextField.text = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        nameTextField.resignFirstResponder()
        
        var scanMatcher: ScanMatching? = nil
        
        if let deviceName = nameTextField.text, deviceName.isNotEmpty {
            scanMatcher = DeviceNameScanMatcher(deviceName: deviceName)
        }
        
        // Connect to a peripheral, optionally perform custom logic, inject RxPeripheral into PeripheralManager
        connectionDisposable =
            connectionManager
            .connectToPeripheral(with: nil, scanMatcher: scanMatcher, options: nil)
            .subscribe(onNext: { [weak self] (peripheral: RxPeripheral) in
                // successfully connected, custom logic
                self?.isConnected = true
                self?.deviceNameTextView.text = peripheral.deviceName ?? "N/A"
                
                // IMPORTANT, MUST DO
                self?.peripheralManager.rxPeripheral = peripheral
            }, onError: { [weak self] (error: Error) in
                // connection lost
                self?.isConnected = false
            })
    }
    
    @IBAction func didTapGAPButton(_ sender: Any) {
        // create a read operation
        let read = Read(service: GattUUIDs.GAP_SVC_UUID, characteristic: GattUUIDs.GAP_DEVICE_NAME_UUID, timeoutSeconds: .seconds(30))
        
        // queue the operation on the gattManager
        peripheralManager
            .queue(operation: read)
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { [weak self] (error) in
                self?.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapBatteryButton(_ sender: Any) {
        peripheralManager
            .queue(operation: Read(service: GattUUIDs.BATTERY_SVC_UUID, characteristic: GattUUIDs.BATTERY_LEVEL_UUID, timeoutSeconds: .seconds(30)))
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { [weak self] (error) in
                self?.consoleLog("Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func didTapDISButton(_ sender: Any) {
        peripheralManager
            .queue(operation: Read(service: GattUUIDs.DIS_SVC_UUID, characteristic: GattUUIDs.DIS_MFG_NAME_UUID, timeoutSeconds: .seconds(30)))
            .subscribe(onSuccess: { _ in
                // read successful
            }, onError: { [weak self] (error) in
                self?.consoleLog("Error: \(error.localizedDescription)")
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
            .subscribe(onNext: { [weak self] (log: RxCBLog) in
                self?.consoleLog(log.message)
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
    
    var match: Observable<ScanData> {
        return scanDataSequence
            .filter { (peripheral: CBPeripheralType, _, _) -> Bool in
                guard let peripheral = peripheral as? CBPeripheral,
                    let name = peripheral.name?.lowercased() else { return false }
              
                return name.contains(self.deviceName.lowercased())
            }
    }
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func accept(_ scanData: ScanData) {
        scanDataSequence.onNext(scanData)
    }
    
    private let deviceName: String
    private let scanDataSequence = ReplaySubject<ScanData>.create(bufferSize: 1)
}

extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}
