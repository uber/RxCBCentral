//
//  ViewController.swift
//  ExampleApp
//
//  Created by Joseph Soultanis on 1/10/19.
//  Copyright © 2019 Joseph Soultanis. All rights reserved.
//

import UIKit
import RxCBCentral

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBOutlet weak var nameTextField: UITextField!
    
    @IBAction func didTapConnect(_ sender: Any) {
        nameTextField.resignFirstResponder()
        
        let connectionManager = CoreConnectionManager(queue: nil, options: nil)
        
        _ = connectionManager
            .connectToPeripheral(with: nil, scanMatcher: nil)
            .subscribe()
        
    }
    
    
    
    private func showConnectionAlert() {
        // create the alert
        let alert = UIAlertController(title: "Invalid Name", message: "No peripheral matches that name. Please enter a valid name.", preferredStyle: UIAlertController.Style.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
}

