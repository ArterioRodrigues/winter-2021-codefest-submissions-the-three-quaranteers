//
//  WelcomeController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/15/21.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import Firebase

class WelcomeViewController: UIViewController {
   
   
    override func viewDidLoad() {
       
        let handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil{
                let mapViewController = self.storyboard?.instantiateViewController(identifier: Constants.Storyboard.mapViewController) as? MapViewController
                self.view.window?.rootViewController = mapViewController
                self.view.window?.makeKeyAndVisible()
                print("USER HERE")
            }
            else{
                //No user is signed in
                //do nothing
                print("NO USER")
            }
        }
        

        super.viewDidLoad()

    }
    
}
