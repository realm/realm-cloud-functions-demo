//
//  Foursquare.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/7/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import CoreLocation

let foursquareClientId = "foursquare client id goes here"
let foursquareClientSecret = "foursquare client secret goes here"
let foursquareAPIVersion = "foursquare api version goes here"

class Foursquare {
    static func getAllLocations(for coordinates: CLLocationCoordinate2D, query: String?, result: @escaping (_ response: FoursquareResponse?, _ error: FoursquareError?) -> Void) {
        let session = URLSession.shared
        var urlString = "https://api.foursquare.com/v2/venues/search?ll=\(coordinates.latitude),\(coordinates.longitude)&client_id=\(foursquareClientId)&client_secret=\(foursquareClientSecret)&v=\(foursquareAPIVersion)"
        if let query = query {
            urlString.append("&query=\(query)")
        }
        guard let url = URL(string: urlString) else {
            return result(nil, nil)
        }
        let task = session.dataTask(with: url) { data, response, error in
            let decoder = JSONDecoder()
            do {
                guard let data = data else {
                    return result(nil, nil)
                }
                let dataResponse = try decoder.decode(FoursquareResponse.self, from: data)
                return result(dataResponse, nil)
            } catch let error {
                return result(nil, FoursquareError(code: 400, reason: error.localizedDescription))
            }
        }
        task.resume()
    }
}
