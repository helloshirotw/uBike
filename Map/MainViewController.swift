//
//  MainViewController.swift
//  Map
//
//  Created by Gary Chen on 13/4/2018.
//  Copyright © 2018 Gary Chen. All rights reserved.
//

import UIKit
import Firebase

class MainViewController: UIViewController {

    //MARK:- Variable
    @IBOutlet weak var userModeSwitch: UISwitch!
    
    @IBOutlet weak var loginView: UIView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBAction func tfUsernameEndEdit(_ sender: UITextField) {
    }
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var buttonOutlet: UIButton!
    
    @IBAction func signInButton(_ sender: UIButton) {
        
        if usernameTextField.text != "" && passwordTextField.text != ""{
            authService(email: usernameTextField.text!, password: passwordTextField.text!)
        }else{
            displayAlert(title: "Sign In Error", message: "Please enter your email and password.")
        }
    }
    
    //MARK:- Methods

    func displayAlert(title:String,message:String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func authService(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            if error != nil {
                let errorString = String(describing: (error! as NSError).userInfo["error_name"]!)
                // If the email is not existed
                if errorString == "ERROR_USER_NOT_FOUND" {
                    // Create User
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if error != nil {
                            self.displayAlert(title: "Create Account Error", message: error!.localizedDescription)
                        } else {
                            // Create Successfully
                            if self.userModeSwitch.isOn {
                                // User is Rider
                                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                changeRequest?.displayName = "Rider"
                                changeRequest?.commitChanges(completion: nil)
                                
                                let riderViewController = RiderViewController(nibName: "RiderViewController", bundle: nil)
                                self.navigate(riderViewController)
                            } else {
                                
                                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                changeRequest?.displayName = "Driver"
                                changeRequest?.commitChanges(completion: nil)
                                
                                let driverViewController = DriverViewController(nibName: "DriverViewController", bundle: nil)
                                self.navigate(driverViewController)
                            }
                        }
                    })
                // Email existed
                } else {
                    // Wrong Password
                    self.displayAlert(title: "Sign In Error", message: error!.localizedDescription)
                }
            } else {
                // Login Successfully
                if user?.displayName == "Rider" {
                    let riderViewController = RiderViewController(nibName: "RiderViewController", bundle: nil)
                    self.navigate(riderViewController)
                } else {
                    let driverViewController = DriverViewController(nibName: "DriverViewController", bundle: nil)
                    self.navigate(driverViewController)
                }
            }
            
        }
    }
    
    func navigate(_ viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func setCorner(_ customView: UIView, radius: CGFloat) {
        customView.layer.cornerRadius = radius
        customView.clipsToBounds = true
    }
    
    //MARK:- Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setCorner(loginView, radius: 10)
    }

    
    
}
