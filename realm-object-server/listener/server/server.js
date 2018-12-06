'use strict';

require('appmetrics-dash').attach()
require('appmetrics-prometheus').attach()
const appName = require('./../package').name
const log4js = require('log4js')
const Realm = require('realm')
const localConfig = require('./config/local.json')
const path = require('path')
const util = require('util')
const request = require('request')

const logger = log4js.getLogger(appName)

var realmObjectServerURL = 'realm object server address goes here'
var realmServerUsername = 'realm object server username goes here'
var realmServerPassword = 'realm object server password goes here'

var ibmCloudFunctionsUsername = 'ibm cloud functions username goes here'
var ibmCloudFunctionsPassword = 'ibm cloud functions password goes here'
var ibmCloudFunctionsNamespace = 'ibm cloud functions namespace goes here'
var ibmCloudFunctionsActionName = 'ibm cloud functions action name goes here'

var notifierPath = "/Hotel"

let adminUser = undefined;

var changeHandler = async function (changeEvent) {
  logger.info('change trigger invoked')
  var updatedRealm = changeEvent.realm
  var venues = updatedRealm.objects('CheckinVenue')
  if (changeEvent.changes['CheckinVenue'].insertions != null) {
    var newIndexes = changeEvent.changes['CheckinVenue'].insertions
    logger.info("inserted indexes", newIndexes)
    for (let venueIndex of newIndexes) {
      logger.info('new venue checkin - calling openwhisk function')
      var venue = venues[venueIndex]
      var restaurants = await getFoodRecommendations(venue.name, venue.latitude, venue.longitude)
      var error = await saveRestaurants(restaurants, venue, updatedRealm)
      if (error != null) {
        logger.error(error)
      }
    }
  }

  if (changeEvent.changes['CheckinVenue'].modifications != null) {
    var updatedIndexes = changeEvent.changes['CheckinVenue'].modifications
    logger.info("updated indexes:", updatedIndexes)
    for (let updatedIndex of updatedIndexes) {
      logger.info('updated venue checkin - calling openwhisk function')
      var venue = venues[updatedIndex]
      var restaurants = await getFoodRecommendations(venue.name, venue.latitude, venue.longitude)
      var error = await saveRestaurants(restaurants, venue, updatedRealm)
      if (error != null) {
        logger.error(error)
      }
    }
  }
}

function saveRestaurants(restaurants, hotel, realm) {
  return new Promise((resolve, reject) => {
    try {
      var existingRestaurants = realm.objects('Restaurant')
      let matchingRestaurants = existingRestaurants.filtered(`venueID = "${hotel.id}"`)
      realm.write(() => {
        logger.info(`removing ${matchingRestaurants.length} restaurants`)
        realm.delete(matchingRestaurants)
        logger.info(`adding ${restaurants.length} restaurants`)
        restaurants.forEach((restaurant) => {
          realm.create('Restaurant', {
            venueID: hotel.id,
            name: restaurant.name,
            latitude: restaurant.latitude,
            longitude: restaurant.longitude,
            distance: restaurant.distance
          })
        })
      })
      resolve()
    } catch (error) {
      reject(error)
    }
  })
}

function getFoodRecommendations(hotelName, latitude, longitude) {
  return new Promise((resolve, reject) => {
    var options = {
      uri: `https://openwhisk.ng.bluemix.net/api/v1/namespaces/${ibmCloudFunctionsNamespace}/actions/${ibmCloudFunctionsActionName}?blocking=true&result=true`,
      method: 'POST',
      body: {
        name: hotelName,
        latitude: latitude,
        longitude: longitude
      },
      json: true,
      auth: {
        user: ibmCloudFunctionsUsername,
        password: ibmCloudFunctionsPassword
      }
    }
    request(options, (err, res, body) => {
      if (err) {
        reject(err)
      } else {
        resolve(body["restaurants"])
      }
    })
  })
}

async function connectToRealm() {
  try {
    adminUser = await Realm.Sync.User.login(`http://${realmObjectServerURL}`, realmServerUsername, realmServerPassword)
    Realm.Sync.addListener(`realm://${realmObjectServerURL}`, adminUser, notifierPath, 'change', changeHandler)
  } catch (error) {
    logger.error(error)
  }
}

connectToRealm()