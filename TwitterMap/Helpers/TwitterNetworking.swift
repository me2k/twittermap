//
//  TwitterNetworking.swift
//  TwitterMap
//
//  Created by Myles Eynon on 15/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import Foundation
import Alamofire
import CoreData

struct TwitterNetworkingKeys {
    
    static let userNameKey = "userName"
    static let delimitedKey = "delimited"
    static let trackKey = "track"
    static let locationsKey = "locations"
    static let baseUrl = "https://stream.twitter.com/1.1/"
    static let loginBaseUrl = "https://api.twitter.com/oauth/request_token"
    
    static let oAuthConsumerKey = "CONSUMER_KEY_HERE"
    static let oAuthConsumerSecret = "CONSUMER_SECRET_HERE"
    static let oAuthAccessToken = "ACCESS_TOKEN_HERE"
    static let oAuthAccessTokenSecret = "ACCESS_TOKEN_SECRET_HERE"
    
    static let ukBoundingRegion = "-11.15,49.12,5.21,59.49"
}

enum TwitterRouter: URLRequestConvertible {

    case GetPublicFeed(String)
    
    var URLRequest: NSMutableURLRequest {
        var route: (path: String, parameters: [String: AnyObject], method: Alamofire.Method) {
            switch self {
            case .GetPublicFeed(let trackPhrases):
                //hard coded lock down to the united kingdom
                let params = [TwitterNetworkingKeys.locationsKey : TwitterNetworkingKeys.ukBoundingRegion, TwitterNetworkingKeys.trackKey : trackPhrases]
                return (TwitterNetworkingKeys.baseUrl + "statuses/filter.json", params, Alamofire.Method.POST)
            }
        }
        
        let URLRequest = NSMutableURLRequest(URL: NSURL(string: route.path)!)
        
        // add custom headers for authentication.
        let defaultHeaders = TwitterNetworking.generateOAuthHeaders(route)
        for header in defaultHeaders {
            URLRequest.setValue(header.1 as? String, forHTTPHeaderField: header.0 as! String)
            print("Header: \(header.0) Value: \(header.1)")
        }
        
        URLRequest.HTTPMethod = route.method.rawValue
        let encoding = Alamofire.ParameterEncoding.URL
        if route.parameters.count > 0 {
            return encoding.encode(URLRequest, parameters: route.parameters).0
        }
        return encoding.encode(URLRequest, parameters: nil).0
    }
}


//Oauth configuration and related methods
class TwitterNetworking {
        
    private static func generateOAuthHeaders(route: (path: String, parameters: [String: AnyObject], method: Alamofire.Method)) -> [NSObject : AnyObject] {
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        var oauthHeaders = [String : AnyObject]()
        
        //Consumer Key
        oauthHeaders["oauth_consumer_key"] = TwitterNetworkingKeys.oAuthConsumerKey
        oauthHeaders["oauth_nonce"] = TwitterNetworking.generateNonce()
        oauthHeaders["oauth_timestamp"] = String(Int(NSDate().timeIntervalSince1970))
        oauthHeaders["oauth_signature_method"] = "HMAC-SHA1"
        oauthHeaders["oauth_version"] = "1.0"
        oauthHeaders["oauth_token"] = TwitterNetworkingKeys.oAuthAccessToken
        var signature = ""
        //create one dictionary with all oauth headers and the parameters as one so we can sort the keys alphabetically.
        var masterDict = oauthHeaders
        for (key, value) in route.parameters {
            masterDict[key] = (value as! String).urlEncode()
        }
        let sortedDict = masterDict.sort { $0.0 < $1.0 }
        for (key, value) in sortedDict {
            if let value = value as? String {
                signature = signature + key + "=" + value + "&"
            }
        }
        if signature.characters.count > 0 {
            //remove the last '&'
            signature = signature.substringToIndex(signature.endIndex.predecessor())
        }
        //concatenate the method in capitals, the URL including the https:// and the parameters each part needs to be URL encoded.
        signature = route.method.rawValue + "&" + route.path.urlEncode() + "&" + signature.urlEncode()
        
        //create the signing key using both secrets. The Access token secret is blank for authorisation requests e.g. login. Here we are using the supplied key from twitter.
        let signingKey = TwitterNetworkingKeys.oAuthConsumerSecret + "&" + TwitterNetworkingKeys.oAuthAccessTokenSecret
        oauthHeaders["oauth_signature"] = signature.hmac(signingKey)
        
        //twitter requires the oauth object set for the Authorization header as "OAUTH KEYS"
        var authorizationString = "OAuth "
        let orderedOauthHeaders = oauthHeaders.sort { $0.0 < $1.0 }
        for (key, value) in orderedOauthHeaders {
            if let value = value as? String {
                authorizationString = authorizationString + key.urlEncode() + "=\"" + value.urlEncode() + "\", "
            }
        }
        //remove the last occurance of '", '
        authorizationString = authorizationString.substringToIndex(authorizationString.endIndex.advancedBy(-2))
        defaultHeaders["Authorization"] = authorizationString
        return defaultHeaders
    }

    private static func generateNonce() -> String {
        let randomData = NSMutableData.init(capacity: 64) //32 bytes is required by the twitter API
        for _ in (0..<32/4) {
            var randomBits = arc4random() as UInt32
            randomData!.appendBytes(&randomBits, length: 4)
        }
        let base64String = randomData!.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        //remove all non alphanumeric characters.
        let result = String(base64String).stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range:nil).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return result.substringToIndex(result.startIndex.advancedBy(32))
    }
}


//Networking calls

extension TwitterNetworking {
    
    class func getPublicTweets(trackText: String, success: (tweet: Tweet) -> Void, failure: (error: ErrorType?) -> Void) -> Void {
        let router = TwitterRouter.GetPublicFeed(trackText)
        Manager.sharedInstance.request(router).stream ({ (streamData) in
            //process this data as a JSON object. this is one tweet at a time.
            do {
                //convert the raw data to a JSON object dictioany in the form [String : AnyObject]
                let tweetJSON = try NSJSONSerialization.JSONObjectWithData(streamData, options: NSJSONReadingOptions.AllowFragments)
                
                //grab managedObjectContext from the appdelegate
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let managedObjectContext = appDelegate.managedObjectContext
                
                //process tweet and save to the DB
                let tweetEntity = NSEntityDescription.entityForName("Tweet", inManagedObjectContext: managedObjectContext)
                let tweet = NSManagedObject(entity: tweetEntity!, insertIntoManagedObjectContext: managedObjectContext) as! Tweet
                let containsData = tweet.setUpWithDictionary(tweetJSON as! [String : AnyObject])
                if containsData {
                    try managedObjectContext.save()
                }
                //alert callback with new tweet object.
                success(tweet: tweet)
                //print("Stream Data: \(tweetJSON)")
            } catch (let error) {
                print("An error occured processing the JSON data: \(error)")
            }
            
        }).responseJSON { response in
            if response.result.error !=  nil {
                failure(error: response.result.error)
                return
            }
        }
    }
    
    class func terminateAllRequests() {
        Manager.sharedInstance.session.getAllTasksWithCompletionHandler { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
}
