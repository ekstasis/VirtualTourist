//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/29/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient {
    
    static let sharedInstance = FlickrClient()
    let urlSession = NSURLSession.sharedSession()
    
    let baseURL = "https://api.flickr.com/services/rest/"
    
    var parameters = [
        "method=flickr.photos.search",
        "api_key=3708e5241ec502d213e35d644fa4a6d8",
        "format=json",
        "nojsoncallback=1",
        "accuracy=14",
        "has_geo=1"
    ]
    
    lazy var context: NSManagedObjectContext = {
        CoreDataStackManager.sharedInstance.managedObjectContext
    }()
    
    func fetchPhotoPaths(pin: Pin, completionHandler: (paths: [String]?, errorString: String?) -> Void) {
        
        parameters.append("lat=\(pin.latitude)")
        parameters.append("lon=\(pin.longitude)")
        
        // API arguments from parameters property above
        let urlString = baseURL + "?" + parameters.joinWithSeparator("&")
        
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        let task = urlSession.dataTaskWithRequest(request) { data, response, error in
            
            guard error == nil else {
                completionHandler(paths: nil, errorString: error!.localizedDescription)
                return
            }
            
            var json = NSDictionary()
            
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
            } catch let error as NSError {
                completionHandler(paths: nil, errorString: error.localizedDescription)
            }
            
            let photosDict = json["photos"] as! [String : AnyObject]
            let photoArray = photosDict["photo"] as! [[String: AnyObject]]
            
            // Generate flickr photo URLs from API JSON
            let paths = photoArray.map { (dict) -> String in
                let farm = dict["farm"] as! Int
                let id = dict["id"] as! String
                let secret = dict["secret"] as! String
                let server = dict["server"] as! String
                return("https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg")
            }
            
            completionHandler(paths: paths, errorString: nil)
        }
        
        task.resume()
    }
    
    func imageDownloadTask(path: String, completionHandler: (imageData: NSData?, errorString: String?) -> Void) -> NSURLSessionDataTask {
        
        let request = NSURLRequest(URL: NSURL(string: path)!)
        
        let task = urlSession.dataTaskWithRequest(request) { data, response, error in
            
            guard error == nil else {
                completionHandler(imageData: nil, errorString: error!.localizedDescription)
                return
            }
            
            completionHandler(imageData: data, errorString: nil)
        }
        
        task.resume()
        return task
    }
}