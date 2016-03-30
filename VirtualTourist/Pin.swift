//
//  Pin.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
   
   @NSManaged var latitude: Double
   @NSManaged var longitude: Double
   @NSManaged var photos: [Photo]
   @NSManaged var availablePages: NSNumber   // updated with each flickr JSON request
   @NSManaged var isDownloading: Bool
   
   var coordinate: CLLocationCoordinate2D {
      get {
         return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      }
      set(newValue) {
         willChangeValueForKey("coordinate")
         latitude = newValue.latitude
         longitude = newValue.longitude
         didChangeValueForKey("coordinate")
      }
   }
   
   // random page value for flickr API request
   var nextPage: Int {
      let pageLimit = FlickrClient.sharedInstance.maxPage // flickr photo limit / per_page
      let maxPage = min(Int(availablePages), pageLimit)
      return Int(arc4random_uniform(UInt32(maxPage))) + 1
   }
   
   override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
      super.init(entity: entity, insertIntoManagedObjectContext: context!)
   }
   
   init(location: CLLocationCoordinate2D, context: NSManagedObjectContext) {
      
      let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
      super.init(entity: entity!, insertIntoManagedObjectContext: context)
      
      latitude = location.latitude
      longitude = location.longitude
      
      availablePages = 1 // updates on subsequent calls to flickr API
   }
   
   override func awakeFromFetch() {
      super.awakeFromFetch()
      isDownloading = false
   }
 
}