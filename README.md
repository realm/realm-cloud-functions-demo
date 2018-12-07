## Realm Cloud Functions - Proof of Concept

This is a repository of a proof-of-concept application stack meant to show how IBM Cloud Functions can extend the functionality of Realm Object Server. This features a cloud function written in Swift that can be triggered whenever new data is injected into Realm Object Server.

The purpose of this application is to demonstrate that Swift developers do not need to learn a new programming language just to write cloud functionality.

### Scenario

Let's assume you are visiting a new city wherespe you don't easily have network connectivity. You finally get to your hotel, and you log onto wifi. The mobile app in this repository allows you to find your hotel via GPS, and get restaurant recommendations nearby. As you check into your hotel, you use the app to find your hotel, and you get 30 restaurant recommendations populated on your map.

Imagine that a year passes. You come back to visit, and you check into the same hotel, but their wifi is down. Thankfully, even with zero network connectivity, the app lets you find the hotel near you, and even see restaurants that were in the area the last time you were there. Suddenly, the hotel wifi comes alive, and you connect. The app will refresh the restaurants for you without you having to do anything on the app. 

This entire workflow is possible thanks to Realm and IBM Cloud Functions. Here's how information traces through the stack:

#### With Connectivity

- Mobile app makes independent call to Foursquare API to retrieve hotels
- Upon retrieval, hotel information is serialized and saved to Realm on iOS device
- Realm library syncs these entries with Realm Object Server, deployed to Kubernetes on IBM Cloud
- Node.js app is constantly listening to Realm Object Server in same Kubernetes cluster, detects update in Realm, calls IBM Cloud Function written in Swift
- Cloud Function calls Foursquare API to query restaurants given latitude/longitude of checked-in hotel, returns native objects in Swift that can be serialized
- Node.js app receives response, adds restaurant entries to Realm Object Server in Kubernetes cluster
- Mobile app picks up changes, broadcasts new restaurants to map view, and adds pins for all of them

#### Without Connectivity

- Mobile app queries Realm for hotels in area, since GPS can be retrieved even in Airplane Mode
- Mobile app displays hotels, user "checks in" to hotel, and check in event is saved to Realm, which restores restaurants associated with that hotel stores in database
- Until network connectivity is restored, nothing happens on device
- As network connectivity is restored, Realm syncs check-in event with Realm Object Server, and the same workflow utilizing IBM Cloud Functions automatically runs again

### Video

[//]: # (repo-assets/realmibmcloudfunctions.mp4)

### Requirements

- Xcode 9.0+
- iOS 11.0+
- Node.js 8.11+
- macOS 10.13+
- Docker for Mac (edge edition) v18.09+
- IBM Cloud Account (for Functions & Kubernetes service)

### How to run

Clone this repository. This document will walk you through installation steps component by component

#### Foursquare

You will need an API Key for Foursquare to make this application work. Visit their [website](https://developer.foursquare.com/) to sign up for a developer account, and keep track of your `client_id` and `client_secret`.

#### IBM Cloud

Sign up for an IBM Cloud account at [https://cloud.ibm.com](https://cloud.ibm.com). Download the CLI for your machine [here](https://console.bluemix.net/docs/cli/reference/ibmcloud/download_cli.html#install_use).

You also need to install Helm, which is the Kubernetes Package Manager. Learn more about how you can install Helm [here](https://github.com/helm/helm).

You have many options for deploying a Kubernetes Cluster, but with IBM Cloud, once you use the Kubernetes service to sign up and provision a single cluster, open Terminal and type the command `ibmcloud cs clusters` to list all clusters in your space. You want to find the ID string associated with your cluster. Copy that string to your computer clipboard.

After that, enter `ibmcloud cs cluster-config **enter your id here**` into Terminal. Copy and paste the string that appears, which should start with `export KUBECONFIG=`.

Enter this entire string into Terminal as a command. You should now have Helm pointed at your deployed Kubernetes cluster in IBM Cloud.

#### Realm Object Server

You must have a feature token for your instance of Realm Object Server. Visit [their website](https://realm.io) to learn more about signing up for your own deployment of Realm Object Server.

After you have set up your account, go into the `realm-object-server` folder in this repository, and open `overrides.yaml`. Copy and paste your feature-token into this line in your file, and save your file. You are now ready to deploy your server to Kubernetes.

In Terminal, navigate to the same directory as `overrides.yaml` and enter the following command:

```
helm init
helm install --name realm-object-server -f overrides.yaml .
```

The first command will install Tiller, if you have not already. You can learn more about what Tiller does [here](https://github.com/helm/helm#helm-in-a-handbasket). After that, you deploy Realm Object Server to your cluster using `overrides.yaml` to override certain standard values in your deployment. 

Realm Object Server, by default, deploys using port 30080, so enter `ibmcloud cs workers **name of your cluster here**`, and open a web browser, then navigate to the public IP that this command gives you, and add `:30080` to the end of the URL. Try to log in with `realm-admin` and a blank password, unless you have specified different values elsewhere in your setup. 

If you are logged in, congratulations - you have deployed Realm Object Server to an IBM Cloud Kubernetes Cluster!

#### Cloud Functions

Log into your IBM Cloud console, and click the hamburger menu at the top left of the page. Scroll down and look for `Functions`. On the left hand side of the resulting page, click `Actions`, and then click on `Create`. Name your action something meaningful, and choose the Swift 4 runtime.

In Terminal, navigate to `getLocations.swift` inside the `cloud-functions` directory. Copy and paste the content of this function into the dev console, making sure to enter your Foursquare API credentials into the appropriate places at the top of the function. A good default value for the API version is `20180808`.

Save this function. On the left hand side, click on `Getting Started`, then `API Key`. Copy and paste your API Key, and get ready to use it in your Node.js listener app. You also want to take note of your Region, Cloud Foundry Org, and Cloud Foundry Space at the top of the screen - you will need the space later.

#### Node.js 

Open Terminal, and navigate to the root directory of your Node.js app. You want to make sure you are using v8.11.1, so if you use Node Version Manager, enter `nvm use 8.11.1`.

Enter `npm install` into Terminal, and let `npm` install your dependencies for you. Open `server/server.js` in a text editor of your choice. Notice the top of the file underneath your package imports, and notice this block of keys:

```
var realmObjectServerURL = 'realm object server address goes here'
var realmServerUsername = 'realm object server username goes here'
var realmServerPassword = 'realm object server password goes here'

var ibmCloudFunctionsUsername = 'ibm cloud functions username goes here'
var ibmCloudFunctionsPassword = 'ibm cloud functions password goes here'
var ibmCloudFunctionsNamespace = 'ibm cloud functions namespace goes here'
var ibmCloudFunctionsActionName = 'ibm cloud functions action name goes here'
```

Enter all the appropriate values here. For your IBM Cloud Functions keys, the username is the API Key, and the password is the API secret - the API key you copied from your website is separated by a colon into the API Key and the secret. Save your file.

Go back to Terminal, and enter `npm start` into Terminal. You should see two strings that your app has connected to the same public IP as your Realm Object Server.

In Terminal, enter `ibmcloud dev build`, and the IBM Cloud CLI will compose a Docker container for you with this application. After this completes, run `ibmcloud dev run`, and you should see similar output to when you ran your application locally. Hit `ctrl+c` to quit your container. 

Run `docker ps -a` and find the name of the container that was created, which should contain the suffix `-run`. Copy and paste the name of that container, and, in Terminal, navigate to `chart/realm-cloud-functions-listener` and open `values.yaml` in a text editor. Edit line 6 to be the name of your container instead of the pre-existing text.

Lastly, from this directory in Terminal, run:

```
helm install --name realm-listener .
```

If all is well, you should have deployed your Node.js listener to the same cluster as Realm Object Server!

#### iOS

This app requires that you have [Cocoapods](https://cocoapods.org/) installed. Once you have Cocoapods on your system, open Terminal and navigate to the same directory for your iOS app as `Podfile`. Enter `pod install` into Terminal, and open `realm-cloud-functions-demo.xcworkspace`. You now have two places to update some values:

1. Open `Realm.swift` and scroll down to line 61, which is a function titled `getRealm()`. Enter your object server url, username, and password here for Realm Object Server.
2. Open `Foursquare.swift` and enter your client id, secret, and API version here.

You can run this application in a simulator, but this is best run on an iOS device to simulate the scenario. Run the app, and follow the above scenario!

### Credits

- [Ian Ward](ian.ward@realm.io)
- [Matt Geerling](matt.geerling@realm.io)
- [David Okun](david.okun@ibm.com)
- [Chris Bailey](baileyc@uk.ibm.com)