//
//  DateConverterHelper.swift
//  TwitterMap
//
//  Created by Myles Eynon on 17/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import Foundation

enum SecondsInCalendarUnit: Double {
    case minute = 60
    case hour = 3600
    case day = 86400
}

class DateConverterHelper {
    
    class func convertTimeStampToTimePast(timeStamp: Int) -> String {
        let tweetTime = NSDate(timeIntervalSince1970: NSTimeInterval(Double(timeStamp) / 1000))

        var timeSinceString = ""
        let timeSince: NSTimeInterval = NSDate().timeIntervalSinceDate(tweetTime)
        if timeSince < SecondsInCalendarUnit.minute.rawValue { //less than a minute
            let seconds: Int = Int(floor(timeSince))
            timeSinceString = "\(seconds)s"
        } else if timeSince < SecondsInCalendarUnit.hour.rawValue { // less than an hour
            let minutes: Int = Int(floor(timeSince / SecondsInCalendarUnit.minute.rawValue))
                timeSinceString = "\(minutes)m"
        } else if timeSince < SecondsInCalendarUnit.day.rawValue { // less than a day
            let hours: Int = Int(floor(timeSince / SecondsInCalendarUnit.hour.rawValue))
            timeSinceString = "\(hours)h"
        } else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.dateFormat = "MMM dd"
            timeSinceString = dateFormatter.stringFromDate(tweetTime)
        }
        return timeSinceString
    }
}
