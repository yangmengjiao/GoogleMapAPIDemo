//
//  ViewController.swift
//  GoogleMapsDemo
//
//  Created by mengjiao on 1/5/21.
//

import UIKit
import GoogleMaps

class GoogleMapViewController: UIViewController {
    //step 1.
    var locationManager: CLLocationManager = CLLocationManager()
    
    // Step 2.
    var mapView = GMSMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Step 3.
        //you need to add this google LicenseInfo somewhere in your app
        print(GMSServices.openSourceLicenseInfo())
        
        // Step 4.
        // Initialize the location manager.
        GoogleMapsHelper.initLocationManager(locationManager, delegate: self)

        //Step 5.
        // Create a map.
        GoogleMapsHelper.createMap(on: view, locationManager: locationManager, mapView: mapView, delegate: self)
        
        //Step 6.
        // draw rout
        let src = CLLocationCoordinate2D(latitude: CLLocationDegrees(28.704060), longitude: CLLocationDegrees(77.102493))
        let dst = CLLocationCoordinate2D(latitude: CLLocationDegrees(28.459497), longitude: CLLocationDegrees(77.026634))
    
        GoogleMapsHelper.draw(src: src, dst: dst)
        
        //calculate duration using google distance matrix api
        GoogleMapsHelper.duration(src: "Washington", dst: "NewYork,NY")

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Step 7.
        // clear map view
        mapView.clear()
    }

}
//MARK：- CLLocationManagerDelegate
//Step 8. Handle GMSMapViewDelegate events
extension GoogleMapViewController: CLLocationManagerDelegate {

    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //
        GoogleMapsHelper.didUpdateLocations(locations, locationManager: locationManager, mapView: mapView)
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Step 8.
        GoogleMapsHelper.handle(manager, didChangeAuthorization: status)
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

//MARK：- GMSMapViewDelegate
//Step 9. Handle GMSMapViewDelegate events
extension GoogleMapViewController: GMSMapViewDelegate {

    //remove info window
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        GoogleMapsHelper.removeInfoWindow()
    }
    
    // when tap marker, add a info window.
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        GoogleMapsHelper.didTap(on: self.view, marker: marker)
    }
}

