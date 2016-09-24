//
//  TweetTableViewCell.swift
//  TwitterMap
//
//  Created by Myles Eynon on 17/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import UIKit
import AlamofireImage

class TweetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tweetLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    func configureWithTweet(tweet: Tweet) {
        if let tweetText = tweet.tweetText {
            self.tweetLabel.text = tweetText
        }
        
        if let userName = tweet.userName, let timeStamp = tweet.timeStamp {
            self.userNameLabel.text = "@" + userName + " ・ " + DateConverterHelper.convertTimeStampToTimePast(timeStamp.integerValue)
        }
        
        if let screenName = tweet.screenName {
            self.screenNameLabel.text = screenName
        }
        if let profileUrl = tweet.profileImageUrl {
            self.profileImageView.af_setImageWithURL(NSURL(string: profileUrl)!)
        }
        profileImageView.layer.cornerRadius = 10
        profileImageView.layer.masksToBounds = true
    }

}
