//
//  LoginController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/15/21.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import Firebase

class LoginViewController: UIViewController {
    
    //this is connected to the welcome page and goes back when tapped

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginConfirmation(_ sender: Any) {
        let emailString = email.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordString = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //Signing in
        Auth.auth().signIn(withEmail: emailString, password: passwordString) { (result, error) in
            if error != nil {
                //couldn't sign in
                self.showError(error!.localizedDescription)
            }
            else{
                self.transitiontoMap()
            }
        }
    }
    
    func showError(_ error : String){
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: { (action) in
            print("Dismissed")
        }))
        present(alert, animated: true)
    }
    func transitiontoMap(){
        let mapViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.mapViewController) as? MapViewController
        view.window?.rootViewController = mapViewController
        view.window?.makeKeyAndVisible()
    }
}
