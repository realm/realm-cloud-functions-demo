//
//  LocationManager.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/7/18.
//  Copyright © 2018 IBM. All rights reserved.
//


import UIKit
import CoreLocation

protocol LocationManagerDelegate {
    func manager(_ manager: LocationManager, didReceiveFirst location: CLLocationCoordinate2D)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    public var lastLoggedLocation: CLLocation?
    var delegate: LocationManagerDelegate?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        if let manager = self.locationManager {
            manager.requestAlwaysAuthorization()
            manager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                manager.delegate = self
                manager.desiredAccuracy = kCLLocationAccuracyBest
                lastLoggedLocation = nil
                manager.startUpdatingLocation()
            }
        }
    }
    
    // MARK: Location Manager Delegate Methods
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\(Date()) - new location gathered -")
        print("\(String(describing: locations.first?.coordinate))")
        DispatchQueue.main.async {
            if let location = manager.location {
                defer {
                    self.lastLoggedLocation = location
                }
                if self.lastLoggedLocation == nil {
                    guard let delegate = self.delegate else {
                        return
                    }
                    self.lastLoggedLocation = location
                    delegate.manager(self, didReceiveFirst: location.coordinate)
                }
            }
        }
    }
}
