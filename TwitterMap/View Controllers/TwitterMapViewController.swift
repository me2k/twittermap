//
//  TwitterMapViewController.swift
//  TwitterMap
//
//  Created by Myles Eynon on 15/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TwitterMapViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startButton: UIBarButtonItem!
    @IBOutlet weak var searchTextField: UITextField!
    
    private var cleanerTimer: NSTimer! //this is our reference to a timer that cleans out the database of old entries.
    private let cleanUpRate = 1 as NSTimeInterval // every second we delete old tweets and refresh the table and map?

    private var managedObjectContext: NSManagedObjectContext? = nil
    private var _fetchedResultsController: NSFetchedResultsController? = nil

    let tweetTimeToLive = 10 as Int //milliseconds a tweet is alowed to be shown for. 10 seconds.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 104
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        
        //show old pins on the map
        let persistentTweets = fetchedResultsController.fetchedObjects as! [Tweet]
        for tweet in persistentTweets {
            addPinToMap(tweet)
        }
        
        //start the tweet engine!
        if let searchTerms = searchTextField.text {
            startStream(searchTerms)
        }
    }
    
    @IBAction func startStopPressed(sender: UIBarButtonItem) {
        if sender.title == "Stop" {
            stopStream()
        } else if let searchTerms = searchTextField.text {
            startStream(searchTerms)
        }
    }
    
    func stopStream() {
        stopCleanUp()
        TwitterNetworking.terminateAllRequests()
        startButton.title = "Start"
    }
    
    func startStream(searchTerms: String) {
        stopCleanUp()
        startButton.title = "Stop"
        cleanerTimer = NSTimer.scheduledTimerWithTimeInterval(cleanUpRate, target: self, selector: #selector(TwitterMapViewController.cleanUpTweets), userInfo: nil, repeats: true)
        TwitterNetworking.getPublicTweets(searchTerms, success: { (tweets) in
            //call back from tweet. We don't do anything here as the NSFetchedResultsController updates the table when data is saved.

        }) { (error) in
            // when the stream is stopped we will get an error!
            if self.startButton.title != "Start" {
                let alertView = UIAlertController(title: "Error Trying to get tweets", message: "Please check your internet connection", preferredStyle: .Alert)
                alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in }))
                self.presentViewController(alertView, animated: true, completion: nil)
            }
        }
    }
    
    func stopCleanUp() {
        if cleanerTimer != nil {
            cleanerTimer.invalidate()
            cleanerTimer = nil
        }
    }
    
    func cleanUpTweets() {
        //grab all the tweets from the database that are older than 10 seconds.
        let fetchRequest = NSFetchRequest(entityName: "Tweet")
        let timeThreshold = NSDate().dateByAddingTimeInterval(NSTimeInterval(-tweetTimeToLive)).timeIntervalSince1970 * 1000 // we multiply by 1000 to match the timeformat in the tweet.
        print("TimeToCompare: \(timeThreshold)")
        fetchRequest.predicate = NSPredicate(format: "%K < %@",  "timeStamp", NSNumber.init(double: timeThreshold))
        do {
            let oldTweets = try managedObjectContext!.executeFetchRequest(fetchRequest) as! [Tweet]
            for oldTweet in oldTweets {
                self.removePinFromMap(oldTweet)
                managedObjectContext!.deleteObject(oldTweet)
            }
            try managedObjectContext!.save()
        } catch {
            print("Error getting old tweets.")
        }
        
    }
    
    // MARK: - Table View
    func configureCell(cell: TweetTableViewCell, tweet: Tweet) {
        cell.configureWithTweet(tweet)
    }

    // MARK: - Map View
    func addPinToMap(tweet: Tweet) {
        if let lat = tweet.latitude, let lng = tweet.longitude, let screenName = tweet.screenName {
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lng.doubleValue)
            pin.title = screenName
            self.mapView.addAnnotation(pin)
        }
    }
    
    func removePinFromMap(tweet: Tweet) {
        if let lat = tweet.latitude, let lng = tweet.longitude {
            for pin in mapView.annotations {
                if pin.coordinate.latitude == lat.doubleValue && pin.coordinate.longitude == lng.doubleValue {
                    self.mapView.removeAnnotation(pin)
                    return //end the for loop so we do not waste time processing useless data.
                }
            }
        }
    }
}

extension TwitterMapViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! TweetTableViewCell
        let tweet = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Tweet
        self.configureCell(cell, tweet: tweet)
        return cell
    }
}

// MARK: - Fetched results controller

extension TwitterMapViewController : NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Tweet", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            addPinToMap(anObject as! Tweet)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.removePinFromMap(anObject as! Tweet)
        case .Update: break
        case .Move: break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}

extension TwitterMapViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text {
            self.stopStream()
            //wait a 100ms otherwise an error will show
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(100.0 * Double(NSEC_PER_MSEC))), dispatch_get_main_queue(), {
                self.startStream(text)
            })
            textField.resignFirstResponder()
        }
        return true
    }
    
}

