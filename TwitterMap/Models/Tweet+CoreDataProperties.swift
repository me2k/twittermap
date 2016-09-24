//
//  Tweet+CoreDataProperties.swift
//  TwitterMap
//
//  Created by Myles Eynon on 17/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Tweet {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var mediaUrl: String?
    @NSManaged var profileImageUrl: String?
    @NSManaged var screenName: String?
    @NSManaged var source: String?
    @NSManaged var timeStamp: NSNumber?
    @NSManaged var tweetText: String?
    @NSManaged var userName: String?

}
