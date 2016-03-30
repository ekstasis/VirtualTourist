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

// NSNotification name for locations with no photos
let NoPhotosNotification = "NoPhotosNotification"
let AllFilesWrittenNotification = "AllFilesWrittenNotification"

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
   let urlSession: NSURLSession
   
   let downloadMOC = CoreDataStackManager.sharedInstance.createPrivateMOC()
   
   var maxPage: Int {
      return photoLimit / photosPerPage
   }
   
   var numImagesToDownload = 0
   
   // MARK: Functions
   
   init() {
      let y = "unecessary"
         let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
         sessionConfig.timeoutIntervalForRequest = 4.0  // For testing error-handling
      urlSession = NSURLSession(configuration: sessionConfig)
   }
   
   func fetchPhotos(mainContextPin: Pin, completionHandler: (String?) -> Void) {
      
      downloadMOC.performBlockAndWait() {
         
//         print(NSThread.currentThread())
         
         let x = "Client property for current pin?  but what happens if two fetches at same time"
         let pin = self.downloadMOC.objectWithID(mainContextPin.objectID) as! Pin
         pin.isDownloading = true
         
         // Download API JSON image paths
         FlickrClient.sharedInstance.fetchPhotoPaths(pin) { imageURLs, pagesAvailable, errorString in
//            print(NSThread.currentThread())
            
            guard errorString == nil else {
               pin.isDownloading = false
               completionHandler(errorString!)
               return
            }
            
            // Create Photos from flickr API JSON image paths
            //            self.downloadMOC.performBlockAndWait() {
            print("fetpaths completion:")
//            print(NSThread.currentThread())
            
            pin.availablePages = pagesAvailable
            
            if let images = imageURLs {
               let _ = images.map { (imageURL) -> Photo in
                  return Photo(imageURL: imageURL, pin: pin, context: self.downloadMOC)
               }
               
               CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
               
               // Downlaod images with client
               FlickrClient.sharedInstance.downloadImages(pin)
               
            } else {
               pin.isDownloading = false // No photos for this location
               CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
            }
            
            //            }
            
         }
      }
   }
   
   func fetchPhotoPaths(pin: Pin, completionHandler: (imageURLs: [String]?, availablePages: NSNumber, errorString: String?) -> Void) {
      
//      print(NSThread.currentThread())
      
      downloadMOC.performBlockAndWait {
         self.parameters.append("lat=\(pin.latitude)")
         self.parameters.append("lon=\(pin.longitude)")
         self.parameters.append("per_page=\(self.photosPerPage)")
         self.parameters.append("page=\(pin.nextPage)")
         
         // API arguments from parameters property above
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
                  let notificationCenter = NSNotificationCenter.defaultCenter()
                  dispatch_async(dispatch_get_main_queue()) {
                     notificationCenter.postNotificationName(NoPhotosNotification, object: nil)
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
               
               print("imageUrls: \(imageURLs.count)")
               
               completionHandler(imageURLs: imageURLs, availablePages: numPages, errorString: nil)
            }
            
         }
         task.resume()
      }
   }
   
   func downloadImages(pin: Pin) {
      
      downloadMOC.performBlockAndWait() {
         
         self.numImagesToDownload = pin.photos.count
         
         guard !pin.photos.isEmpty else {
            pin.isDownloading = false
            print("pin photos empty??")
            return
         }
         
         for photo in pin.photos {
            
            let url = NSURL(string: photo.imageURL)
            let request = NSURLRequest(URL: url!)
            
            let task = self.urlSession.dataTaskWithRequest(request) { data, response, error in
               
               self.downloadMOC.performBlockAndWait {
                  
                  guard error == nil else {
                     print(error)
                     return
                  }
                  
                  let fileName = url!.lastPathComponent!
                  let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
                  let filePath = fileDirectory.URLByAppendingPathComponent(fileName)
                  
                  let image = UIImage(data: data!)!
                  let imageToBeSaved = UIImageJPEGRepresentation(image, 1.0)!
                  
                  if imageToBeSaved.writeToFile(filePath.path!, atomically: true) {
                     
//                     self.downloadMOC.performBlockAndWait() {
                        photo.fileName = fileName
                        CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
//                     }
                     
                     // Alerts Album View that downloads are complete
                     self.numImagesToDownload = self.numImagesToDownload - 1
                     if self.numImagesToDownload == 0 {
                        pin.isDownloading = false
                        CoreDataStackManager.sharedInstance.saveContext(self.downloadMOC)
                        dispatch_async(dispatch_get_main_queue()) {
                           NSNotificationCenter.defaultCenter().postNotificationName(AllFilesWrittenNotification, object: nil)
                        }
                     }
                  }
               }
            }
            task.resume()
         }
      }
   }
}