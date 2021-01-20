//
//  SignUpController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/15/21.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var confirmEmail: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
    }

    @IBAction func signUpConfirmation(_ sender: Any) {
        //Check if the fields are correct
        let validate = validation()
        if validate != nil{
            showError(validate!)
        }
        else{
            //Create cleaned version of the data
            let emailString = email.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let usernameString = username.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let passwordString = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            //Create User
            Auth.auth().createUser(withEmail: emailString, password: passwordString) { (result, err) in
                //check errors
                if err != nil{
                    self.showError("Error creating user")
                }
                else{
                    
                    //User was created successfully, store the username
                    let db = Firestore.firestore()
                    db.collection("users").addDocument(data: ["username":usernameString, "uid": result!.user.uid]) { (error) in
                        
                        if error != nil{
                            self.showError("Couldn't be added to collection")
                        }
                    }
                    //Transition to Maps
                    self.transitiontoMap()
                }
            }
        }
    }
    
    func transitiontoMap(){
        let mapViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.mapViewController) as? MapViewController
        view.window?.rootViewController = mapViewController
        view.window?.makeKeyAndVisible()
    }
    //Validates the field and returns nil if it's correct, otherwise return error message
    func validation() -> String?{
        if username.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            password.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            email.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            confirmEmail.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            confirmEmail.text?.trimmingCharacters(in: .whitespacesAndNewlines) != email.text?.trimmingCharacters(in: .whitespacesAndNewlines){
            
            return "Please enter correct info."
        }
        
        let checkPassword = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPasswordValid(checkPassword) == false{
            return "Check if password length is 8, at least contain one alphabet in password, and one special character in password."
        }
        return nil
    }
    
    func isPasswordValid(_ password : String) -> Bool{
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
    
    func showError(_ error : String){
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: { (action) in
            print("Dismissed")
        }))
        present(alert, animated: true)
    }
    
}
