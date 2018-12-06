struct FoursquareVenue: Codable {
    struct FoursquareVenueLocation: Codable {
        var lat: Double?
        var lng: Double?
        var distance: Double?
    }
    var name: String
    var location: FoursquareVenueLocation?
}

struct FoursquareItem: Codable {
    var venue: FoursquareVenue?
}

struct FoursquareGroup: Codable {
    var items: [FoursquareItem]?
}

struct FoursquareResponse: Codable {
    var groups: [FoursquareGroup]?
}

struct APIResponse: Codable {
    var response: FoursquareResponse
}

struct Restaurant: Codable {
    var name: String
    var associatedHotel: Hotel
    var latitude: Double
    var longitude: Double
    var distance: Double
}

struct RestaurantResponse: Codable {
    var restaurants: [Restaurant]?
}

struct Hotel: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
}

enum FoursquareError: Error {
    case badParams
    case noResponse
    case badResponse
    case other
}

let clientID = "foursquare client id goes here"
let clientSecret = "foursquare client secret goes here"
let apiversion = "foursquare api version goes here"

func mapResponse(with data: Data, for associatedHotel: Hotel) -> [Restaurant]? {
    let decoder = JSONDecoder()
    let response = try? decoder.decode(APIResponse.self, from: data)
    guard let items = response?.response.groups?.first?.items else {
        return nil
    }
    var restaurants = [Restaurant]()
    for item in items {
        guard let venue = item.venue, let latitude = venue.location?.lat, let longitude = venue.location?.lng, let distance = venue.location?.distance else {
            continue
        }
        let newRestaurant = Restaurant(name: venue.name, associatedHotel: associatedHotel, latitude: latitude, longitude: longitude, distance: distance)
        restaurants.append(newRestaurant)
    }
    return restaurants
}

func retrieveRestaurants(for hotel: Hotel, completion: @escaping ([Restaurant]?, Error?) -> Void) {
    let urlString = "https://api.foursquare.com/v2/venues/explore?ll=\(hotel.latitude),\(hotel.longitude)&client_id=\(clientID)&client_secret=\(clientSecret)&v=\(apiversion)&query=dinner"
    guard let url = URL(string: urlString) else {
        return completion(nil, FoursquareError.badParams)
    }
    let session = URLSession.shared
    let dataTask = session.dataTask(with: url) { data, response, error in
        guard let data = data else {
            return completion(nil, FoursquareError.noResponse)
        }
        guard let restaurants = mapResponse(with: data, for: hotel) else {
            return completion(nil, FoursquareError.noResponse)
        }
        completion(restaurants, nil)
    }
    dataTask.resume()
}

func main(param: Hotel, completion: @escaping (RestaurantResponse?, Error?) -> Void) -> Void {
    retrieveRestaurants(for: param) { restaurants, error in
        completion(RestaurantResponse(restaurants: restaurants), error)
    }
}
