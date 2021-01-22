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
class MapViewController: UIViewController, GMSMapViewDelegate{

    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    @IBOutlet weak var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 10.0
    var ref: DatabaseReference!
    var oldRoute: GMSPolyline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //To add functionality to mapview delegate, this needs to be done 
        mapView.delegate = self
        let button = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        button.setTitle("Button", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        self.view.addSubview(button)
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        

        // A default location to use when location permission is not granted.
        let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
        
        // Create a map.
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        drawMarkers()
    }
    
    
    //When the view loads, it'll draw the markers onto the map
    func drawMarkers(){
        ref = Database.database().reference()
        ref.child("Location").observeSingleEvent(of: .value, with: { snapshot in
            let dict = snapshot.value as! NSDictionary
            for (key, _)in dict{
                if let coord = dict[key] as? String {
                    let str = coord.components(separatedBy: ",")
                    let lat = (str[0] as NSString).doubleValue
                    let long = (str[1] as NSString).doubleValue
                    let position = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    let marker = GMSMarker(position: position)
                    marker.title = "Random Location"
                    marker.snippet = "Hopefully this works"
                    marker.map = self.mapView
                }
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
                    if self.oldRoute != nil{
                        self.oldRoute.map = nil
                    }
                    self.oldRoute = polyline
                    self.oldRoute.map = self.mapView
                    
                }
            }
            catch let error{
                print(error.localizedDescription)
            }
            
        }
    }
    
    //We might delete this, but i'll have it here just in case
    @objc func handleTap(_ sender: UIButton) {
        // Add the map to the view, hide it until we've got a location update.
        let destination = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude + 0.005, longitude: locationManager.location!.coordinate.longitude + 0.005)
        let marker = GMSMarker()
        marker.position = destination
        marker.title = "Random Location"
        marker.snippet = "Hopefully this works"
        marker.map = mapView
        drawPath(destination: destination)
    }
    
    //This checks when the button was pressed
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let destination = CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude)
        drawPath(destination: destination)
        print("YUURRRRR")
        return true
    }
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {

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
