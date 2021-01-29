//
//  PopUpViewControllerjViewController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/27/21.
//

import UIKit
import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import FirebaseDatabase
class ReviewPopUpViewController: UIViewController {
    @IBOutlet weak var ReviewPopUp: UIView!
    var places: GMSPlace!
    @IBOutlet weak var add: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var clean: UISwitch!
    @IBOutlet weak var accessibility: UISwitch!
    @IBOutlet weak var customerOnly: UISwitch!
    @IBOutlet weak var sharedBathroom: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func addFirestore(_ sender: Any) {
        self.view.removeFromSuperview()
        //ADDS DOCUMENT TO FIRESTORE WITHOUT ISSUES
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        ref = db.collection("locations").addDocument(data: [
            "name": places.name!,
            "address": places.formattedAddress!,
            "latitude": places.coordinate.latitude,
            "longitude": places.coordinate.longitude,
            "cleanliness": clean.isOn, //this determines if the bathroom is clean or not
            "accessible": accessibility.isOn, //On means that it has features to help those who need it
            "customer": customerOnly.isOn, //On Means that you must pay a fee
            "shared": sharedBathroom.isOn //On means that there's more than one toilet in the bathroom
        ]){ err in
            if let err = err{
                print("Error adding document: \(err)")
            } else{
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
