//
//  FoursquareObjects.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/8/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

struct FoursquareLocation: Codable {
    var address: String?
    var lat: Double?
    var lng: Double?
    var distance: Double?
    var postalCode: String?
    var city: String?
    var state: String?
    var country: String?
}

struct FoursquareVenue: Codable {
    var id: String
    var name: String
    var location: FoursquareLocation
}

struct FoursquareData: Codable {
    var venues: [FoursquareVenue]?
}

struct FoursquareResponse: Codable {
    var response: FoursquareData?
}

struct FoursquareError: Codable {
    var code: Int?
    var reason: String?
}
