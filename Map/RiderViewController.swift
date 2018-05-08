//
//  RiderViewController.swift
//  Map
//
//  Created by Gary Chen on 16/4/2018.
//  Copyright © 2018 Gary Chen. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase
class RiderViewController: CustomViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var callButton: UIButton!
    
    let locationManager = CLLocationManager()
    var didCall = false
    var userLoaction = CLLocationCoordinate2D()
    let reference: DatabaseReference = Database.database().reference()
    
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Request user permission
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingLocation()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.updateLocation()
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate: CLLocationCoordinate2D = manager.location?.coordinate {
            
            userLoaction = coordinate
            
            if driverOnTheWay {
                displayDriverAndRider()
            } else {
                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0018, longitudeDelta: 0.0018))
                mapView.setRegion(region, animated: true)
                
                mapView.removeAnnotations(mapView.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "My Location"
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func updateLocation() {
        if let email = Auth.auth().currentUser?.email {
            reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (dataSnapShot) in
                self.callMode()
                
            if let driverRequestDic = dataSnapShot.value as? [String: Any] {
                guard let driverLatitude = driverRequestDic["driverLatitude"] as? Double,
                    let driverLongitude = driverRequestDic["driverLongitude"] as? Double else { return }
                self.driverLocation = CLLocationCoordinate2D(latitude: driverLatitude, longitude: driverLongitude)
                self.driverOnTheWay = true
                self.displayDriverAndRider()
                self.reference.child("RiderRequest").removeAllObservers()
                }
            })
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLoaction.latitude, longitude: userLoaction.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        callButton.setTitle("Your driver is \(roundedDistance)km away", for: .normal)
        
        mapView.removeAnnotations(mapView.annotations)
        
        let riderAnnotation = MKPointAnnotation()
        riderAnnotation.coordinate = userLoaction
        riderAnnotation.title = "Me"
        mapView.addAnnotation(riderAnnotation)
        
        let driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = driverLocation
        driverAnnotation.title = "Driver"
        mapView.addAnnotation(driverAnnotation)
        
        let latitudeDelta = abs(driverLocation.latitude - userLoaction.latitude) * 2.5
        let longitudeDelta = abs(driverLocation.longitude - userLoaction.longitude) * 2.5
        
        let region = MKCoordinateRegion(center: userLoaction, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func callButtonTapped(_ sender: UIButton) {
        // Get user email
        
        if !driverOnTheWay {
            
            guard let email = Auth.auth().currentUser?.email else { return }
            
            if didCall {
                reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(DataEventType.childAdded, with: { (datasnapShot) in
                    datasnapShot.ref.removeValue()
                    self.reference.child("RiderRequest").removeAllObservers()
                })
                cancelMode()
            } else {
                // Call
                let riderRequestDic: [String: Any] = ["email": email, "latitude": userLoaction.latitude, "longitude": userLoaction.longitude]
                // Save to firebase database
                reference.child("RiderRequest").childByAutoId().setValue(riderRequestDic)
                callMode()
            }
        }
        
        
    }
    
    func callMode() {
        callButton.setTitle("Cancel", for: .normal)
        callButton.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        didCall = true
    }
    
    
    func cancelMode() {
        callButton.setTitle("Call", for: .normal)
        callButton.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        didCall = false
    }
    
}
