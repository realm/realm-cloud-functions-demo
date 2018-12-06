//
//  Models.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/27/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import RealmSwift
import MapKit

class PotentialCheckinVenue: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class CheckinVenue: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var lastCheckedIn: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Restaurant: Object {
    @objc dynamic var venueID: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var distance: Double = 0
}

class CheckinVenueAnnotation: NSObject, MKAnnotation {
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
    var coordinate: CLLocationCoordinate2D
    var title: String?
}

class PotentialCheckinVenueAnnotation: NSObject, MKAnnotation {
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
    var coordinate: CLLocationCoordinate2D
    var title: String?
}

class RestaurantAnnotation: NSObject, MKAnnotation {
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
    var coordinate: CLLocationCoordinate2D
    var title: String?
}
