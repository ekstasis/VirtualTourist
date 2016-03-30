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

let NoPhotosNotification = "NoPhotosNotification" // Location has no associated Photos on Flickr
let AllFilesWrittenNotification = "AllFilesWrittenNotification" // all images are downloaded and saved

class FlickrClient {
   
   // MARK: Properties
   
   // flickr photo limit undocumented change from 4000 to ~2000?  To be safe:
   let photoLimit = 1000
   let photosPerPage = 40
   
   let baseURL = "https://api.flickr.com/services/rest/"
   var parameters = [
      "method=flickr.photos.search",
      "api_key=3708e5241ec502d213e35d644fa4a6d8",
      "format=json",
      "nojsoncallback=1",
      "accuracy=14",
      "has_geo=1",
   ]
   
   static let sharedInstance = FlickrClient()
   let urlSession = NSURLSession.sharedSession()
   
   // shared MOC for all client tasks
   let downloadMOC = CoreDataStackManager.sharedInstance.createPrivateMOC()
   
   // based on Flickr photo download limit above
   var pageLimit: Int {
      return photoLimit / photosPerPage
   }
   
   // tracks if we're done downloading and saving
   var numImagesToDownload = 0
   
   // MARK: Functions
   
   func fetchPhotos(mainContextPin: Pin, completionHandler: (String?) -> Void) {
      
      downloadMOC.performBlockAndWait() {
         
         let pin = self.downloadMOC.objectWithID(mainContextPin.objectID) as! Pin
         pin.isDownloading = true
         
         // Download API JSON image paths
         FlickrClient.sharedInstance.fetchPhotoPaths(pin) { imageURLs, numPagesForLocation, errorString in
            
            guard errorString == nil else {
               pin.isDownloading = false
               completionHandler(errorString!)
               return
            }
            
            pin.numPagesForLocation = numPagesForLocation
            
            // Create Photos from flickr URLs and start downloading
            if let images = imageURLs {
               let _ = images.map { (imageURL) -> Photo in
                  return Photo(imageURL: imageURL, pin: pin, context: self.downloadMOC)
               }
               CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
               FlickrClient.sharedInstance.downloadImages(pin)
               
            } else { // no photos for location, notification was sent in main function
               pin.isDownloading = false // No photos for this location
               CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
            }
            completionHandler(nil)
         }
      } // end performBlockAndWait
   }
   
   func fetchPhotoPaths(pin: Pin, completionHandler: (imageURLs: [String]?, availablePages: NSNumber, errorString: String?) -> Void) {
      
      downloadMOC.performBlockAndWait {
         self.parameters.append("lat=\(pin.latitude)")
         self.parameters.append("lon=\(pin.longitude)")
         self.parameters.append("per_page=\(self.photosPerPage)")
         self.parameters.append("page=\(pin.nextPage)")
      } // end performBlockAndWait
      
      let urlString = self.baseURL + "?" + self.parameters.joinWithSeparator("&")
      let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
      
      let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
         
         self.downloadMOC.performBlockAndWait {
            
            guard error == nil else {
               completionHandler(imageURLs: nil, availablePages: 0, errorString: error!.localizedDescription)
               return
            }
            
            var json = NSDictionary()
            do {
               json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
            } catch let error as NSError {
               completionHandler(imageURLs: nil, availablePages: 0, errorString: error.localizedDescription)
            }
            
            let photosDict = json["photos"] as! [String : AnyObject]
            let photoArray = photosDict["photo"] as! [[String: AnyObject]]
            let numPages = photosDict["pages"] as! NSNumber
            
            guard !photoArray.isEmpty else {
               pin.isDownloading = false
               dispatch_async(dispatch_get_main_queue()) {
                  NSNotificationCenter.defaultCenter().postNotificationName(NoPhotosNotification, object: nil)
               }
               completionHandler(imageURLs: nil, availablePages: 0, errorString: nil)
               return
            }
            
            // Generate flickr photo URLs from API JSON
            let imageURLs = photoArray.map { (dict) -> String in
               let farm = dict["farm"] as! Int
               let id = dict["id"] as! String
               let secret = dict["secret"] as! String
               let server = dict["server"] as! String
               return("https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg")
            }
            
            completionHandler(imageURLs: imageURLs, availablePages: numPages, errorString: nil)
         }
      } // end performBlockAndWait
      task.resume()
   }
   
   func downloadImages(pin: Pin) {
      
      downloadMOC.performBlockAndWait() {
         
         self.numImagesToDownload = pin.photos.count
         
         for photo in pin.photos {
            
            let imageURL = NSURL(string: photo.imageURL)
            let request = NSURLRequest(URL: imageURL!)
            
            let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
               
               
               guard error == nil else {  // fail quietly for individual image download error
                  return
               }
               
               let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
               let fileName = imageURL!.lastPathComponent!
               let filePath = fileDirectory.URLByAppendingPathComponent(fileName)
               
               let image = UIImage(data: data!)!
               let imageToBeSaved = UIImageJPEGRepresentation(image, 1.0)!
               
               if imageToBeSaved.writeToFile(filePath.path!, atomically: true) {
                  
                  self.downloadMOC.performBlockAndWait {
                     photo.fileName = fileName
                     CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
                  }
                  
                  self.numImagesToDownload--
                  
                  // Alerts Album View if downloads are complete
                  if self.numImagesToDownload == 0 {
                     dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName(AllFilesWrittenNotification, object: nil)
                     }
                     
                     self.downloadMOC.performBlockAndWait() {
                        pin.isDownloading = false
                        CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
                     }
                  }
               }
            }
            task.resume()
         } // end for loop
      } // end performBlockAndWait
   }
}