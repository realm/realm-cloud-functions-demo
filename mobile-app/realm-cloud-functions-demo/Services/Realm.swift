//
//  Realm.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/27/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

enum RealmError: Error {
    case badURL(String)
    case badCredentials(String, String)
    case badConfiguration(Realm.Configuration)
    case other(Error?)
}

protocol RealmLayerDelegate: class {
    func loadedRestaurants(from layer: RealmLayer, restaurants: [Restaurant], networkLatest: Bool)
    func loadedPotentialVenues(from layer: RealmLayer, venues: [PotentialCheckinVenue])
}

class RealmLayer {
    fileprivate var realm: Realm?
    fileprivate var notificationToken: NotificationToken?
    fileprivate var checkinVenues: Results<CheckinVenue>?
    fileprivate var restaurants: Results<Restaurant>?
    fileprivate var potentialVenues: Results<PotentialCheckinVenue>?
    weak var delegate: RealmLayerDelegate?
    
    init() {
        RealmLayer.getRealm { (realm, error) in
            if let realm = realm {
                self.realm = realm
                self.checkinVenues = realm.objects(CheckinVenue.self)
                self.restaurants = realm.objects(Restaurant.self)
                self.potentialVenues = realm.objects(PotentialCheckinVenue.self)
                self.notificationToken = self.restaurants?.observe { changes in
                    switch changes {
                    case .update(_, _, _, _):
                        print("changes to restaurants")
                        guard let restaurants = self.restaurants else {
                            return
                        }
                        var formed = [Restaurant]()
                        for restaurant in restaurants {
                            formed.append(restaurant)
                        }
                        self.delegate?.loadedRestaurants(from: self, restaurants: formed, networkLatest: true)
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private static func getRealm(completion: @escaping (Realm?, Error?) -> Void) {
        let objectServerURL = "realm object server url goes here"
        let realmUsername = "username goes here (default is realm-admin)"
        let realmPassword = "password goes here (default is empty string)"
        
        guard let url = URL(string: "http://\(objectServerURL)") else {
            return completion(nil, RealmError.badURL(objectServerURL))
        }
        guard let realmURL = URL(string: "realm://\(objectServerURL)/Hotel") else {
            return completion(nil, RealmError.badURL(objectServerURL))
        }
        let credentials = SyncCredentials.usernamePassword(username: realmUsername, password: realmPassword)
        SyncUser.logIn(with: credentials, server: url) { user, error in
            if let error = error {
                return completion(nil, RealmError.other(error))
            }
            DispatchQueue.main.async {
                guard let user = user else {
                    return
                }
                Realm.Configuration.defaultConfiguration = Realm.Configuration(syncConfiguration: SyncConfiguration(user: user, realmURL: realmURL), objectTypes: [CheckinVenue.self, Restaurant.self, PotentialCheckinVenue.self])
                do {
                    let realm = try Realm(configuration: Realm.Configuration.defaultConfiguration)
                    return completion(realm, nil)
                } catch let error {
                    return completion(nil, RealmError.other(error))
                }
            }
        }
    }
    
    public func savePotentialVenues(_ venues: [PotentialCheckinVenue]) {
        guard let realm = realm else {
            return
        }
        do {
            realm.beginWrite()
            realm.add(venues, update: true)
            try realm.commitWrite()
        } catch {
            print(error)
            return
        }
    }
    
    public func getPotentialVenues(near location: CLLocationCoordinate2D) {
        guard let potentialVenues = potentialVenues else {
            return
        }
        var relevantVenues = [PotentialCheckinVenue]()
        let mainLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        for venue in potentialVenues {
            let queryLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
            if mainLocation.distance(from: queryLocation) < 20000 {
                relevantVenues.append(venue)
            }
        }
        delegate?.loadedPotentialVenues(from: self, venues: relevantVenues)
    }
    

    public func checkIn(to venue: CheckinVenue) {
        guard let realm = realm else {
            return
        }
        do {
            guard let checkinVenues = checkinVenues else {
                return
            }
            let matchingVenues = checkinVenues.filter { $0.id == venue.id }
            realm.beginWrite()
            venue.lastCheckedIn = Date()
            realm.add(venue, update: matchingVenues.count > 0)
            try realm.commitWrite()
            guard let isReachable = Network.reachability?.isReachable else {
                return
            }
            if !isReachable {
                print("no network - responding with cached restaurants")
                guard let restaurants = restaurants else {
                    return
                }
                var relevantRestaurants = [Restaurant]()
                for restaurant in restaurants {
                    if restaurant.venueID == venue.id {
                        relevantRestaurants.append(restaurant)
                    }
                }
                delegate?.loadedRestaurants(from: self, restaurants: relevantRestaurants, networkLatest: false)
            }
        } catch let error {
            print(error)
            return
        }
    }
}
