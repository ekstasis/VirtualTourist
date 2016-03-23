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
   
   // flickr photo limit undocumented change from 4000 to ~2000?  To be safe:
   let photoLimit = 1000
   let photosPerPage = 2
   
   var maxPage: Int {
      return photoLimit / photosPerPage
   }
   
   static let sharedInstance = FlickrClient()
   let urlSession = NSURLSession.sharedSession()
   
   let baseURL = "https://api.flickr.com/services/rest/"
   
   var parameters = [
      "method=flickr.photos.search",
      "api_key=3708e5241ec502d213e35d644fa4a6d8",
      "format=json",
      "nojsoncallback=1",
      "accuracy=14",
      "has_geo=1",
   ]
   
   func fetchPhotoPaths(pin: Pin, completionHandler: (imageURLs: [String]?, availablePages: NSNumber?, errorString: String?) -> Void) {
      
      parameters.append("lat=\(pin.latitude)")
      parameters.append("lon=\(pin.longitude)")
      parameters.append("per_page=\(photosPerPage)")
      parameters.append("page=\(pin.nextPage)")
      
      // API arguments from parameters property above
      let urlString = baseURL + "?" + parameters.joinWithSeparator("&")
      let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
      
      let task = urlSession.dataTaskWithRequest(request) { data, response, error in
         
         guard error == nil else {
            completionHandler(imageURLs: nil, availablePages: nil, errorString: error!.localizedDescription)
            return
         }
         
         var json = NSDictionary()
         
         do {
            json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
         } catch let error as NSError {
            completionHandler(imageURLs: nil, availablePages: nil, errorString: error.localizedDescription)
         }
         
         let photosDict = json["photos"] as! [String : AnyObject]
         let photoArray = photosDict["photo"] as! [[String: AnyObject]]
         let numPages = photosDict["pages"] as! NSNumber
         
         // Generate flickr photo URLs from API JSON
         let imageURLs = photoArray.map { (dict) -> String in
            let farm = dict["farm"] as! Int
            let id = dict["id"] as! String
            let secret = dict["secret"] as! String
            let server = dict["server"] as! String
            return("https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg")
         }
         
         print("imageURL count = \(imageURLs.count)")
         
         completionHandler(imageURLs: imageURLs, availablePages: numPages, errorString: nil)
      }
      
      task.resume()
   }
   
   func downloadImages(iPin: Pin) {
      
      let downloadImageMOC = CoreDataStackManager.sharedInstance.createPrivateMOC()
      
      downloadImageMOC.performBlockAndWait() {
         
         let pin = downloadImageMOC.objectWithID(iPin.objectID) as! Pin
         
         print("photos count:")
         print(pin.photos.count)
         
         for photo in pin.photos {
            
            let url = NSURL(string: photo.imageURL)
            let request = NSURLRequest(URL: url!)
            
            let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
               
               guard error == nil else {
                  //            completionHandler(imageData: nil, errorString: error!.localizedDescription)
                  return
               }
               
               let fileName = url!.lastPathComponent!
               let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
               let filePath = fileDirectory.URLByAppendingPathComponent(fileName)
               
               let image = UIImage(data: data!)!
               let imageToBeSaved = UIImageJPEGRepresentation(image, 1.0)!
               imageToBeSaved.writeToFile(filePath.path!, atomically: true)
               
               downloadImageMOC.performBlockAndWait() {
                  photo.fileName = fileName
                  print("set filename")
                  CoreDataStackManager.sharedInstance.saveContext(downloadImageMOC)
               }
            }
            task.resume()
         }
      }
   }
}