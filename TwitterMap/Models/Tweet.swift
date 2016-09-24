//
//  Tweet.swift
//  TwitterMap
//
//  Created by Myles Eynon on 17/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import UIKit

//keys used by the twitter JSON data stream

struct TweetKeys {
    static let tweetTextKey = "text"
    static let timeStampKey = "timestamp_ms"
    static let sourceKey = "source"
    static let userKey = "user"
    static let entitiesKey = "entities"
    static let mediaKey = "media"
    static let userNameKey = "name"
    static let userScreenNameKey = "screen_name"
    static let geoEnabledKey = "geo_enabled"
    static let latitudeKey = "latitude"
    static let longitudeKey = "longitude"
    static let profileURLKey = "profile_image_url_https"
    static let mediaURLKey = "media_url_https"
    static let coordinatesKey = "coordinates"
    static let placeKey = "place"
    static let boundingBoxKey = "bounding_box"
    static let typeKey = "type"
}

class Tweet: NSManagedObject {

    //populate the tweet entity using the tweet dictionary.
    func setUpWithDictionary(dict: [String : AnyObject]) -> Bool {
        var hasData = false
        if let tweetText = dict[TweetKeys.tweetTextKey] as? String {
            self.tweetText = tweetText
            hasData = true
        }
        
        if let timeStamp = dict[TweetKeys.timeStampKey] as? String {
            self.timeStamp = NSNumber.init(longLong: Int64(timeStamp)!)
            print("Tweet Time: \(timeStamp)")
        }
        
        if let source = dict[TweetKeys.sourceKey] as? String {
            self.source = source
        }
        
        if let tweetEntityObject = dict[TweetKeys.entitiesKey] as? [String : AnyObject], let mediaObject = tweetEntityObject[TweetKeys.mediaKey] as? [String : AnyObject], let mediaUrl = mediaObject[TweetKeys.mediaURLKey] as? String {
            self.mediaUrl = mediaUrl
        }
        
        if let userObject = dict[TweetKeys.userKey] as? [String : AnyObject] {
            if let userName = userObject[TweetKeys.userNameKey] as? String {
                self.userName = userName
            }
            if let screenName = userObject[TweetKeys.userScreenNameKey] as? String {
                self.screenName = screenName
            }
            if let imageURL = userObject[TweetKeys.profileURLKey] as? String {
                self.profileImageUrl = imageURL
            }
        }
        
        //Tweet coordinates can come from three different parts of the tweet json model, geo, coordinates and place. We are only taking the coordinates and place cases into consideration as geo is deprecated. 
        if let coordinate = dict[TweetKeys.coordinatesKey] as? [Double] where coordinate.count >= 2 {
            self.latitude = NSNumber.init(double: coordinate[0])
            self.longitude = NSNumber.init(double: coordinate[1])
        } else if let placeDict = dict[TweetKeys.placeKey] as? [String : AnyObject], let boundingBoxDict = placeDict[TweetKeys.boundingBoxKey] as? [String : AnyObject] {
            if let coordinates = boundingBoxDict[TweetKeys.coordinatesKey] as? [[[Double]]] {
                self.latitude = NSNumber.init(double: coordinates[0][0][1])
                self.longitude = NSNumber.init(double: coordinates[0][0][0])
            }
        }
        return hasData
    }


}
