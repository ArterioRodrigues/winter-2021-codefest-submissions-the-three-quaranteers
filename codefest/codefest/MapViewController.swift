//
//  ViewController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/12/21.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire
import Firebase
import FirebaseDatabase
class MapViewController: UIViewController, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate{

    @IBOutlet weak var test: UIButton!
    
    
    var locationManager: CLLocationManager!
    var selectedButton: Bool!
    var currentLocation: CLLocation?
    @IBOutlet weak var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 10.0
    var ref: DatabaseReference!
    @IBOutlet weak var searchButton: UIButton!
    var passOver: GMSPlace!
    @IBOutlet weak var addButton: UIButton!
    var oldRoute: GMSPolyline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //To add functionality to mapview delegate, this needs to be done
        mapView.delegate = self
        
        do{
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json"){
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }else{
                NSLog("Unable to find style.json")
            }
        }catch{
                NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        /*let button = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        button.setTitle("Button", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        self.view.addSubview(button)*/
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        // Create a map.
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        drawMarkers()
        
        
    }
    
    
    
    //When the view loads, it'll draw the markers onto the map
    func drawMarkers(){
        let db = Firestore.firestore()
        db.collection("locations").addSnapshotListener({ [self]querySnapshot, error in
            guard let documents = querySnapshot?.documents else{
                print("Error fetching document: \(error!)")
                return
            }
            for document in documents{
                print("\(document.documentID) => \(document.data())")
                print(type(of: document.data()["longitude"]))
                let lat = document.data()["latitude"]
                let long = document.data()["longitude"]
                let name =  document.data()["name"]
                let address = document.data()["address"]
                let position = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: long as! CLLocationDegrees)
                let marker = GMSMarker()
                marker.position = position
                marker.title = name as? String
                marker.snippet = address as? String
                marker.map = self.mapView
            }
        })
    }
    
    //This function allows us to draw the path when the user clicks on the marker
    func drawPath(destination: CLLocationCoordinate2D){
        let currentlocation = locationManager.location!.coordinate
        let start = "\(currentlocation.latitude),\(currentlocation.longitude)"
        let end = "\(destination.latitude),\(destination.longitude)"
        let url =  "https://maps.googleapis.com/maps/api/directions/json?origin=\(start)&destination=\(end)&mode=walking&key=AIzaSyCa7QvPcW4LRhbflCGpU6_J23iwyl-XwOE"
        AF.request(url).responseJSON { (response) in
            guard let data = response.data else {
                return
            }
            do{
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                for route in routes{
                    let overview_polyline = route["overview_polyline"].dictionary
                    let points = overview_polyline?["points"]?.string
                    let path = GMSPath.init(fromEncodedPath: points ?? "")
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeColor = .systemGreen
                    polyline.strokeWidth = 5
                    if(self.oldRoute != nil){
                        if(polyline.path?.encodedPath() == self.oldRoute.path?.encodedPath()){ //encoded string of the path compared to each other
                            self.oldRoute.map = nil //this turns off the direction if the user presses on it again
                            self.oldRoute = nil
                        }
                        else{
                                self.oldRoute.map = nil
                                self.oldRoute = nil
                                self.oldRoute = polyline
                                self.oldRoute.map = self.mapView
                        }
                    }
                    else{
                        self.oldRoute = polyline
                        self.oldRoute.map = self.mapView
                    }
                    
 
                    
                    
                    
                }
            }
            catch let error{
                print(error.localizedDescription)
            }
            
        }
    }
    
    
    //This checks when the button was pressed
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let destination = CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude)
        drawPath(destination: destination)
        mapView.selectedMarker = marker
        return true
    }
    
    @IBAction func autcompleteClicked(_ sender: UIButton) {
        if sender == addButton{
                selectedButton = true
        }
        let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self

            // Specify the place data types to return.
        let fields: GMSPlaceField = [.all]
            autocompleteController.placeFields = fields

            // Specify a filter.
            let filter = GMSAutocompleteFilter()
        filter.type = .establishment
            autocompleteController.autocompleteFilter = filter

            // Display the autocomplete view controller.
            present(autocompleteController, animated: true, completion: nil)
        

    }
    
    //extension MapViewController: GMSAutocompleteViewControllerDelegate{
    
    // Handle the user's selection.
      func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place ID: \(place.placeID)")
        print("Place Location: \(place.coordinate)")
        print("Latitude: \(place.coordinate.latitude)")
        print("Longitude: \(place.coordinate.longitude)")
        if (selectedButton == true){
            
            passOver = place
            selectedButton = false
            let popover = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PopUp") as! PopUpViewController
            self.addChild(popover)
            popover.view.frame = self.view.frame
            self.view.addSubview(popover.view)
            popover.didMove(toParent: self)
            popover.places = place
            popover.name.text = place.formattedAddress!
            passOver = nil
        }
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            zoom: zoomLevel)
        mapView.animate(to: camera)
        dismiss(animated: true, completion: nil)
      }

        
      func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
      }

      // User canceled the operation.
      func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
      }

      // Turn the network activity indicator on and off again.
      func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
       // UIApplication.shared.isNetworkActivityIndicatorVisible = true
      }

      func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
       // UIApplication.shared.isNetworkActivityIndicatorVisible = false
      }
}



// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate{

  // Handle incoming location events.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location: CLLocation = locations.last!
    print("Location: \(location)")
    let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
    let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: zoomLevel)
    mapView.animate(to: camera)
  }

  // Handle authorization for the location manager.
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // Check accuracy authorization
    let accuracy = manager.accuracyAuthorization
    switch accuracy {
    case .fullAccuracy:
        print("Location accuracy is precise.")
    case .reducedAccuracy:
        print("Location accuracy is not precise.")
    @unknown default:
      fatalError()
    }
    
    // Handle authorization status
    switch status {
    case .restricted:
      print("Location access was restricted.")
    case .denied:
      print("User denied access to location.")
      // Display the map using the default location.
      mapView.isHidden = false
    case .notDetermined:
      print("Location status not determined.")
    case .authorizedAlways: fallthrough
    case .authorizedWhenInUse:
      print("Location status is OK.")
    @unknown default:
      fatalError()
    }
  }

  // Handle location manager errors.
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationManager.stopUpdatingLocation()
    print("Error: \(error)")
  }
    
}

