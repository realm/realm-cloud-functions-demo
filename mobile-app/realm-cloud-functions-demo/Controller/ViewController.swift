//
//  ViewController.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/7/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    private var locationManager: LocationManager?
    private var mostRecentCoordinates: CLLocationCoordinate2D?
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var checkInButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var resetButton: UIButton!
    
    var timer = Timer()
    
    var currentFocusVenue: CheckinVenue?
    var currentVenues: [CheckinVenue]?
    var currentPotentialVenues: [PotentialCheckinVenue]?
    var currentRestaurants: [Restaurant]?
    
    var currentVenueAnnotations: [CheckinVenueAnnotation]?
    var currentRestaurantAnnotations: [RestaurantAnnotation]?
    var currentPotentialVenueAnnotations: [PotentialCheckinVenueAnnotation]?
    var realmLayer = RealmLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = LocationManager()
        
        if let locationManager = locationManager {
            locationManager.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleButtons()
        setupMapView()
        updateStatusView(statusView)
        updateResetButtonUI(resetButton)
        updateStatusLabel(with: "Let's find a place to stay.")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension ViewController { // UI Modification
    private func styleButtons() {
        checkInButton.backgroundColor = "6D67E8".hexColor
        checkInButton.layer.cornerRadius = 8.0
        checkInButton.titleLabel?.font = UIFont.IBMFonts.medium(size: 18)
    }
    
    private func setupMapView() {
        mapView.showsUserLocation = true
        mapView.delegate = self
        self.realmLayer.delegate = self
    }
    
    private func updateStatusView(_ view: UIView) {
        view.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        view.layer.shadowOffset = CGSize(width: 1.0, height: 3.0)
        view.layer.shadowOpacity = 0.65
        view.layer.shadowRadius = 3.0
        view.layer.cornerRadius = 3.0
        view.layer.masksToBounds = false
    }
    
    private func updateResetButtonUI(_ button: UIButton) {
        button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        button.layer.shadowOffset = CGSize(width: 1.0, height: 3.0)
        button.layer.shadowOpacity = 0.65
        button.layer.shadowRadius = 3.0
        button.layer.cornerRadius = 22.0
        button.layer.masksToBounds = false
    }
    
    private func updateStatusLabel(with text: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = text
        }
    }
}

extension ViewController { // IBActions
    @IBAction func resetButtonTapped() {
        currentVenues = nil
        currentPotentialVenues = nil
        currentVenueAnnotations = nil
        currentPotentialVenueAnnotations = nil
        currentRestaurantAnnotations = nil
        currentRestaurants = nil
        mapView.removeAnnotations(mapView.annotations)
        if let location = mostRecentCoordinates {
            let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            let region = MKCoordinateRegion(center: location, span: span)
            self.mapView.setRegion(region, animated: true)
        }
        updateStatusLabel(with: "Let's find a place to stay.")
    }
    
    @IBAction func checkInButtonTapped() {
        guard let reachability = Network.reachability else {
            return
        }
        guard let location = mostRecentCoordinates else {
            return // show alert view?
        }
        if !reachability.isReachable {
            realmLayer.getPotentialVenues(near: location)
            return
        }
        updateStatusLabel(with: "Searching for hotels in your area...")
        currentVenues = nil
        currentPotentialVenues = nil
        currentVenueAnnotations = nil
        currentPotentialVenueAnnotations = nil
        mapView.removeAnnotations(mapView.annotations)
        Foursquare.getAllLocations(for: location, query: "hotel") { response, error in
            DispatchQueue.main.async {
                guard let response = response, let venues = response.response?.venues else {
                    return
                }
                self.currentVenues = nil
                self.currentPotentialVenues = nil
                
                var locations = [CheckinVenueAnnotation]()
                var checkinVenues = [CheckinVenue]()
                var potentialVenues = [PotentialCheckinVenue]()
                for venue in venues {
                    guard let latitude = venue.location.lat, let longitude = venue.location.lng else {
                        continue
                    }
                    let pin = CheckinVenueAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: venue.name)
                    locations.append(pin)
                    let checkin = CheckinVenue()
                    let potential = PotentialCheckinVenue()
                    checkin.id = venue.id
                    potential.id = venue.id
                    checkin.name = venue.name
                    potential.name = venue.name
                    checkin.latitude = latitude
                    potential.latitude = latitude
                    checkin.longitude = longitude
                    potential.longitude = longitude
                    checkinVenues.append(checkin)
                    potentialVenues.append(potential)
                }
                self.updateStatusLabel(with: "Here are \(checkinVenues.count) hotels that are near you right now.")
                self.currentVenues = checkinVenues
                self.currentVenueAnnotations = locations
                self.mapView.showAnnotations(locations, animated: true)
                self.realmLayer.savePotentialVenues(potentialVenues)
            }
        }
    }
}

extension ViewController: LocationManagerDelegate {
    func manager(_ manager: LocationManager, didReceiveFirst location: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            let region = MKCoordinateRegion(center: location, span: span)
            self.mapView.setRegion(region, animated: true)
            self.mostRecentCoordinates = location
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else if annotation is CheckinVenueAnnotation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "checkinVenue")
            view.pinTintColor = .blue
            view.animatesDrop = true
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .contactAdd)
            return view
        } else if annotation is RestaurantAnnotation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "restaurant")
            view.pinTintColor = .red
            view.animatesDrop = true
            view.canShowCallout = true
            return view
        } else if annotation is PotentialCheckinVenueAnnotation {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "potentialcheckinvenue")
            view.pinTintColor = "269ED9".hexColor
            view.animatesDrop = true
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .contactAdd)
            return view
        } else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if view.reuseIdentifier == "checkinVenue" {
            let title = view.annotation?.title
            let latitude = view.annotation?.coordinate.latitude
            let longitude = view.annotation?.coordinate.longitude
            guard let venues = currentVenues else {
                return
            }
            let filteredVenues = venues.filter {
                $0.longitude == longitude && $0.latitude == latitude && $0.name == title
            }
            guard let venue = filteredVenues.first else {
                return
            }
            let alertController = UIAlertController(title: "Check into the \(venue.name)?", message: nil, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { action in
                self.currentFocusVenue = venue
                self.realmLayer.checkIn(to: venue)
                self.updateStatusLabel(with: "Looking for restaurants near \(venue.name)...")
                if let annotations = self.currentRestaurantAnnotations {
                    mapView.removeAnnotations(annotations)
                }
            }
            let noAction = UIAlertAction(title: "No", style: .destructive, handler: nil)
            alertController.addAction(noAction)
            alertController.addAction(yesAction)
            present(alertController, animated: true, completion: nil)
        } else if view.reuseIdentifier == "potentialcheckinvenue" {
            let title = view.annotation?.title
            let latitude = view.annotation?.coordinate.latitude
            let longitude = view.annotation?.coordinate.longitude
            guard let venues = currentPotentialVenues else {
                return
            }
            let filteredVenues = venues.filter {
                $0.longitude == longitude && $0.latitude == latitude && $0.name == title
            }
            guard let potentialVenue = filteredVenues.first else {
                return
            }
            let alertController = UIAlertController(title: "Check into the \(potentialVenue.name)?", message: nil, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { action in
                let venue = CheckinVenue()
                venue.id = potentialVenue.id
                venue.latitude = potentialVenue.latitude
                venue.longitude = potentialVenue.longitude
                venue.name = potentialVenue.name
                self.currentFocusVenue = venue
                self.realmLayer.checkIn(to: venue)
                self.updateStatusLabel(with: "Looking for restaurants near \(venue.name)...")
                if let annotations = self.currentRestaurantAnnotations {
                    mapView.removeAnnotations(annotations)
                }
            }
            let noAction = UIAlertAction(title: "No", style: .destructive, handler: nil)
            alertController.addAction(noAction)
            alertController.addAction(yesAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension ViewController: RealmLayerDelegate {
    func loadedRestaurants(from layer: RealmLayer, restaurants: [Restaurant], networkLatest: Bool) {
        if restaurants.count < 1 {
            if mapView.annotations.count > 1 {
                updateStatusLabel(with: "We could not find any restaurants near you right now.")
            }
            return
        }
        if let annotations = currentRestaurantAnnotations {
            mapView.removeAnnotations(annotations)
        }
        currentRestaurantAnnotations = nil
        currentRestaurants = nil
        var restaurantPins = [RestaurantAnnotation]()
        var newRestaurants = [Restaurant]()
        for restaurant in restaurants.filter({ $0.venueID == currentFocusVenue?.id }) {
            let latitude: CLLocationDegrees = restaurant.latitude
            let longitude: CLLocationDegrees = restaurant.longitude
            let name: String = restaurant.name
            let pin = RestaurantAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: name)
            restaurantPins.append(pin)
            newRestaurants.append(restaurant)
        }
        currentRestaurants = newRestaurants
        currentRestaurantAnnotations = restaurantPins

        if !networkLatest {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(drawRestaurantAnnotations), userInfo: nil, repeats: false)
        } else {
            updateStatusLabel(with: "Here are the best \(restaurantPins.count) restaurants near you right now.")
            mapView.showAnnotations(restaurantPins, animated: true)
        }
    }
    
    @objc private func drawRestaurantAnnotations() {
        guard let annotations = currentRestaurantAnnotations else {
            return
        }
        updateStatusLabel(with: "Here are the best \(annotations.count) restaurants that were near you last time you were here.")
        mapView.showAnnotations(annotations, animated: true)
    }
    
    @objc private func drawPotentialVenueAnnotations() {
        guard let annotations = currentPotentialVenueAnnotations else {
            return
        }
        updateStatusLabel(with: "Here are \(annotations.count) hotels that were near you last time you were here.")
        mapView.showAnnotations(annotations, animated: true)
    }
    
    func loadedPotentialVenues(from layer: RealmLayer, venues: [PotentialCheckinVenue]) {
        currentPotentialVenues = nil
        currentPotentialVenueAnnotations = nil
        currentVenues = nil
        currentVenueAnnotations = nil
        currentRestaurants = nil
        currentRestaurantAnnotations = nil
        mapView.removeAnnotations(mapView.annotations)
        var venuePins = [PotentialCheckinVenueAnnotation]()
        for venue in venues {
            let latitude: CLLocationDegrees = venue.latitude
            let longitude: CLLocationDegrees = venue.longitude
            let name: String = venue.name
            let pin = PotentialCheckinVenueAnnotation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: name)
            venuePins.append(pin)
        }
        currentPotentialVenueAnnotations = venuePins
        currentPotentialVenues = venues
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(drawPotentialVenueAnnotations), userInfo: nil, repeats: false)
    }
}
