//
//  ViewController.swift
//  RaspEye
//
//  Created by Ege Çavuşoğlu on 7/8/19.
//  Copyright © 2019 Ege Çavuşoğlu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var titleCont: UIView!
    @IBOutlet weak var featuresContainer: UIView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var settingsLabel: UILabel!
    
    @IBOutlet weak var addressText: UITextField!
    @IBOutlet weak var portText: UITextField!
    @IBOutlet weak var widthText: UITextField!
    @IBOutlet weak var heightText: UITextField!
    @IBOutlet weak var fpsText: UITextField!
    @IBOutlet weak var bpsText: UITextField!
    
    
    //Instance variables
    var camera = Camera()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        screenLayout()
        let tap = UITapGestureRecognizer(target: self, action: #selector(keyboardDisappear) )
        view.addGestureRecognizer(tap)
    }
    
    @objc func keyboardDisappear() {
        view.endEditing(true)
    }
    
    @IBAction func launchButton(_ sender: Any) {
        // Camera must be instanstiated and started here
        var allValidInput: Bool = true
        let alert = UIAlertController(title: "Input Validation Error", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        // Sanitizing input before assigning it to the "camera"
        guard let address = addressText.text, address.length > 0 else {
            allValidInput = false
            alert.message = "No IP Address was entered."
            self.present(alert, animated: true)
            return
        }
        guard Utils.isIpAddress(address) || Utils.isHostname(address) else {
            allValidInput = false
            alert.message = "IP Address is not valid"
            self.present(alert, animated: true)
            return
        }
        guard let port = Int(portText.text!) else {
            allValidInput = false
            alert.message = "Port address is not valid"
            self.present(alert, animated: true)
            return
        }
        
        // Assigning the user input parameters to the Camera object.
        camera.name = "cameraName"
        camera.address = address
        camera.port = port
        
        // Segue is performed if specified input parameters are sanitized. (IP Address and Port)
        if allValidInput {
        performSegue(withIdentifier: "goToCamera", sender: Any?.self)
        }
    }
    
    // This method is used to transfer data to the CameraViewController. The "camera" object is moved through the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let vc = segue.destination as? CameraViewController, segue.identifier == "goToCamera" {
             vc.camera = camera
        }
   
    }
    
    
    // Auto layout using code.
       func screenLayout () {
            titleCont.translatesAutoresizingMaskIntoConstraints = false
            titleCont.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
            titleCont.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            titleCont.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            titleCont.heightAnchor.constraint(equalToConstant: 100).isActive = true

            settingsLabel.textAlignment = .center
            settingsLabel.translatesAutoresizingMaskIntoConstraints = false
            settingsLabel.topAnchor.constraint(equalTo: titleCont.topAnchor).isActive = true
            settingsLabel.bottomAnchor.constraint(equalTo: titleCont.bottomAnchor).isActive = true
            settingsLabel.leadingAnchor.constraint(equalTo: titleCont.leadingAnchor).isActive = true
            settingsLabel.trailingAnchor.constraint(equalTo: titleCont.trailingAnchor).isActive = true

            featuresContainer.translatesAutoresizingMaskIntoConstraints = false
            featuresContainer.topAnchor.constraint(equalTo: titleCont.bottomAnchor).isActive = true
            featuresContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            featuresContainer.trailingAnchor.constraint(equalTo: inputContainer.leadingAnchor).isActive = true
            featuresContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true

            inputContainer.translatesAutoresizingMaskIntoConstraints = false
            inputContainer.topAnchor.constraint(equalTo: titleCont.bottomAnchor).isActive = true
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            inputContainer.widthAnchor.constraint(equalTo: featuresContainer.widthAnchor, multiplier: 1).isActive = true
            inputContainer.heightAnchor.constraint(equalTo: featuresContainer.heightAnchor).isActive = true
            
        }
}
