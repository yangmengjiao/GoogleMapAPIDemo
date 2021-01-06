//
//  GoogleMapsHelper.swift
//  GoogleMapsDemo
//
//  Created by mengjiao on 1/5/21.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

/// help deal with any google map related stuff.
struct GoogleMapsHelper {
    
    private static var mapView: GMSMapView!
    
    private static var preciseLocationZoomLevel: Float = 15.0
    private static var approximateLocationZoomLevel: Float = 10.0
    
    private static var infoWindow = MapMarkerWindow()
    fileprivate static var locationMarker : GMSMarker? = GMSMarker()
    
    // model lists
    private static var routesArray = [Route]()
    private static var durationArray = [Duration]()
    
    // init location manager with delegate
    static func initLocationManager(_ locationManager: CLLocationManager, delegate: UIViewController) {
        var locationManager =  locationManager
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }
    
    //add map to view
    static func createMap(on view: UIView, locationManager: CLLocationManager, mapView: GMSMapView, delegate: UIViewController) {
        // zoomlevel for camera
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        
        //default camera
        let camera = GMSCameraPosition.camera(withLatitude: 40.730610,
                                              longitude: -73.935242,
                                              zoom: zoomLevel)
        // set map view
        var mapView = mapView
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = delegate as? GMSMapViewDelegate
        self.mapView = mapView
        
        // add info window
        self.infoWindow = loadNiB()
        view.addSubview(mapView)
    }
    
    //calculate duration
    static func duration(src: String, dst: String) {
        // Create URL
        let url =
            "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=\(src),DC&destinations=\(dst)&key=\(Constant.googleApiKey)"
        
        
        // request
        AF.request(url).responseJSON { (reseponse) in
            guard let data = reseponse.data else {
                return
            }
            
            do {
                let jsonData = try JSON(data: data)
                let rows = jsonData["rows"].arrayValue
                
                //convert rows into our Duration model
                for row in rows {
                    let elements = row["elements"].arrayValue
                    for element in elements {
                        let duration = element["duration"].dictionary
                        
                        if let text = duration?["text"]?.string {
                            let duration = Duration(text: text)
                            self.durationArray += [duration]
                        }
                    }
                }
                
                // test : just print out the durations that we get from distance matrix api
                
                self.durationArray.forEach {
                    print($0)
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    //draw path
    static func draw(src: CLLocationCoordinate2D, dst: CLLocationCoordinate2D){
        
        // source location and destination
        let sourceLocation = "\(src.latitude),\(src.longitude)"
        let destinationLocation = "\(dst.latitude),\(dst.longitude)"
        
        // Create URL
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(sourceLocation)&destination=\(destinationLocation)&mode=driving&key=\(Constant.googleApiKey)"
        
        // request
        AF.request(url).responseJSON { (reseponse) in
            guard let data = reseponse.data else {
                return
            }
            
            do {
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                
                //convert route into our Route model
                for route in routes {
                    let overview_polyline = route["overview_polyline"].dictionary
                    let points = overview_polyline?["points"]?.string
                    let r = Route(points: points)
                    self.routesArray += [r]
                }
                
                // asyn update ui
                DispatchQueue.main.async {
                    for route in self.routesArray {
                        let path = GMSPath.init(fromEncodedPath: route.points ?? "")
                        let polyline = GMSPolyline.init(path: path)
                        polyline.strokeColor = .systemBlue
                        polyline.strokeWidth = 5
                        polyline.map = self.mapView
                    }
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
        
        // test data for source Marker
        let sourceMarker = GMSMarker()
        sourceMarker.position = src
        var data = [String : String]()
        data["name"] = "meng"
        sourceMarker.userData = data
        sourceMarker.map = self.mapView
        
        //customize icon
        let pin = UIImage(named: "car.png")!.resize(targetSize: CGSize(width: 40, height: 40))
        sourceMarker.icon = pin
        
        // test data for destinatio Marker
        let destinationMarker = GMSMarker()
        destinationMarker.position = dst
        destinationMarker.title = "Gurugram"
        destinationMarker.snippet = "The hub of industries"
        destinationMarker.map = self.mapView
        
        let camera = GMSCameraPosition(target: sourceMarker.position, zoom: 10)
        self.mapView.animate(to: camera)
    }
    
    //MARK：- Handle methods
    
    // reset camera
    static func didUpdateLocations(_ locations: [CLLocation], locationManager: CLLocationManager, mapView: GMSMapView) {
        let location: CLLocation = locations.last!
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView.camera = camera
    }
    
    // handle authorization
    static func handle(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
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
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
    
    //MARK：- Handle GMSMapViewDelegate methods
    
    // show info winder of marker
    static func didTap(on view: UIView, marker: GMSMarker) -> Bool {
        var markerData : NSDictionary?
        if marker.userData == nil {
            return false
        }
        
        if let data = marker.userData! as? NSDictionary {
            markerData = data
        }
        locationMarker = marker
        infoWindow.removeFromSuperview()
        infoWindow = loadNiB()
        guard let location = locationMarker?.position else {
            print("locationMarker is nil")
            return false
        }
        // Pass the spot data to the info window, and set its delegate to self
        infoWindow.spotData = markerData
        
        infoWindow.alpha = 0.9
        infoWindow.layer.cornerRadius = 12
        infoWindow.layer.borderWidth = 2
        
        
        let name = markerData!["name"]!
        
        infoWindow.infoLabel.text = name as? String
        
        infoWindow.center = mapView.projection.point(for: location)
        infoWindow.center.y = infoWindow.center.y - 82
        view.addSubview(infoWindow)
        return false
    }
    
    // remove info window
    static func removeInfoWindow() {
        self.infoWindow.removeFromSuperview()
    }
    
    //MARK：- Help functions
    
    // return an instance of the custom view class
    static func loadNiB() -> MapMarkerWindow {
        let infoWindow = MapMarkerWindow.instanceFromNib() as! MapMarkerWindow
        return infoWindow
    }
}

//MARK：- UIImage Extension
private extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
}



