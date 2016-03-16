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
   @NSManaged var numPages: NSNumber   // updated from each flickr JSON request
   
   // iPhone 4 32-bit Int shenanigans
//   var numPages: Int {
//      get {
//         return Int(numPages64)
//      }
//      set {
//         numPages64 = Int64(newValue)
//      }
//   }
   
   var coordinate: CLLocationCoordinate2D {
      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
   }
   
   // random page value for flickr API request
   var nextPage: Int {
      let pageLimit = FlickrClient.sharedInstance.maxPage // flickr photo limit / per_page
      let maxPage = min(Int(numPages), pageLimit)
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
      
      numPages = 1 // updates on subsequent calls to flickr API
   }
}