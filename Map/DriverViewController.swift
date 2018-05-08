//
//  DriverViewController.swift
//  Map
//
//  Created by Gary Chen on 16/4/2018.
//  Copyright © 2018 Gary Chen. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import MapKit
import CoreLocation

class DriverViewController: CustomViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickUpButton: UIButton!
    
    let reference = Database.database().reference()
    var riderRequests: [DataSnapshot] = []
    let locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    var driverAnnotation = MKPointAnnotation()
    var selectedRow: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let driverTableViewCell = UINib(nibName: "DriverTableViewCell", bundle: nil)
        tableView.register(driverTableViewCell, forCellReuseIdentifier: "driverCell")
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        pickUpButton.isHidden = true
        // Update Rider Location
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (timer) in
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        retrieveData()
    }
    
    @IBAction func pickUpTapped(_ sender: UIButton) {
        let riderRequestDic = riderRequests[selectedRow!].value as? [String: Any]
        
        reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: riderRequestDic?["email"]).observeSingleEvent(of: .childAdded) { (dataSnapShot) in
            dataSnapShot.ref.updateChildValues(["driverLatitude": self.driverLocation.latitude, "driverLongitude": self.driverLocation.longitude])
            let riderCLLocation = CLLocation(latitude: riderRequestDic!["latitude"] as! Double, longitude: riderRequestDic!["longitude"] as! Double)
            CLGeocoder().reverseGeocodeLocation(riderCLLocation, completionHandler: { (clPlacemarks, error) in
                if error != nil {
                     print(error!)
                } else {
                    if let placemarks = clPlacemarks {
                        if placemarks.count > 0 {
                            let placemark = MKPlacemark(placemark: placemarks[0])
                            let mapItem = MKMapItem(placemark: placemark)
                            mapItem.name = riderRequestDic!["email"] as? String
                            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        }
                    }
                }
            })
            
            
            
        }
    }
    func retrieveData() {
        // Observe data -> get dataSnapShot.value
        
        reference.child("RiderRequest").observe(DataEventType.childAdded) { (dataSnapShot) in
            
            if let riderRequestDic = dataSnapShot.value as? [String: Any] {
                guard riderRequestDic["driverLatitude"] == nil else { return }
            }
            self.riderRequests.append(dataSnapShot)
            dataSnapShot.ref.removeAllObservers()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        if let coordinate = manager.location?.coordinate {
            
            driverLocation = coordinate
            
            //Set Map view
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
            
            self.mapView.removeAnnotation(driverAnnotation)
            driverAnnotation.coordinate = coordinate
            driverAnnotation.title = "Me"
            mapView.addAnnotation(driverAnnotation)
        }
    }
    
    
    
}

extension DriverViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return riderRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "driverCell", for: indexPath) as! DriverTableViewCell
        
        let riderRequest = riderRequests[indexPath.row]
        
        if let riderRequestDic = riderRequest.value as? [String: Any] {
            
            guard let email = riderRequestDic["email"] as? String,
            let latitude = riderRequestDic["latitude"] as? Double,
            let longitude = riderRequestDic["longitude"] as? Double,
            let image = UIImage(named: "username") else { return UITableViewCell()}
            
            // Using CLLocation for calculating distance
            let riderCLLocation = CLLocation(latitude: latitude, longitude: longitude)
            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
            let distance = riderCLLocation.distance(from: driverCLLocation) / 1000

            let roundedDistance = round(distance * 100) / 100
            
            let riderDetail  = "\(roundedDistance)km away."
            cell.configureCell(profileImage: image, email: email, detail: riderDetail)
            
            // Update rider location in map
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            annotation.title = "Rider"
            mapView.addAnnotation(annotation)
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let riderRequest = riderRequests[indexPath.row]
        if let riderRequestDic = riderRequest.value as? [String: Any] {
            
            guard let latitude = riderRequestDic["latitude"] as? Double,
                let longitude = riderRequestDic["longitude"] as? Double else { return }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            self.mapView.setRegion(region, animated: true)
        }
        pickUpButton.isHidden = false
        selectedRow = indexPath.row
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// add image to annotation
extension DriverViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.image = UIImage(named: "owl.png")

        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

