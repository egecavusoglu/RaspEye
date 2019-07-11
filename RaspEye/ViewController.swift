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
    
    @objc func keyboardDisappear(){
        
        view.endEditing(true)
    }
    
    @IBAction func launchButton(_ sender: Any) {
        // Camera must be instanstiated and started here
       
//
//        guard let address = addressText.text, address.length > 0 else
//        {
//            Utils.error(self, "errorNoAddress")
//            return false
//        }
//        guard Utils.isIpAddress(address) || Utils.isHostname(address) else
//        {
//            Utils.error(self, "errorBadAddress")
//            return false
//        }
//        guard let port = Utils.getIntTextField(self, portIntField, "port")
//            else
//        {
//            return false
//        }
        
        // assign the new values to the camera
        camera.name = "cameraName"
        //camera.network = networkLabel.text!
        camera.address = addressText.text!
        camera.port = Int(portText.text!)!
        
        
       
        
        // Segue is performed
        performSegue(withIdentifier: "goToCamera", sender: Any?.self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    if segue.identifier == "goToCamera" {
//        guard let vc = segue.destination as? CameraViewController else {return}
//         let camera = sender as? Camera 
//        vc.camera = Camera(camera)
//        }
        if let vc = segue.destination as? CameraViewController, segue.identifier == "goToCamera" {
             vc.camera = camera
        }
   
    }
    
    
    
    func screenLayout () {
//        view.addConstraints("V:|-30-[v0(100)][v1]-100-|", views: titleCont, featuresContainer)
//        view.addConstraints("V:|-30-[v0(100)][v1]-100-|", views: titleCont, inputContainer)
//        view.addConstraints("H:|[v0][v1(==v0)]|", views: featuresContainer, inputContainer)
//        view.addConstraints("H:|[v0]|", views: titleCont)
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

//extension UIView {
//    /// Add constraints with visual format
//    ///
//    /// - Parameters:
//    ///   - format: Visual format just change the view names with v0,v1,v2...
//    ///   - views: Views for the constraints
//    /// - Example:
//    /// ``` self.view.addConstraints(_ format: "V:|-20-[v0]-20-|", views:contentView) ```
//    func addConstraints(_ format: String, views: UIView...) {
//        var viewsDictionary = [String: UIView]()
//        for (index, view) in views.enumerated() {
//            let key = "v\(index)"
//            viewsDictionary[key] = view
//            view.translatesAutoresizingMaskIntoConstraints = false
//        }
//        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
//    }
//}
