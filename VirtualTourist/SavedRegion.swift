//
//  SavedRegion.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import CoreData
import MapKit

class SavedRegion: NSManagedObject {
   
   @NSManaged var latitude: Double
   @NSManaged var longitude: Double
   @NSManaged var spanLatitudeDelta: Double
   @NSManaged var spanLongitudeDelta: Double
   
   var region: MKCoordinateRegion {
      get {
         let mapCenter = CLLocationCoordinate2DMake(latitude, longitude)
         let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
         return MKCoordinateRegionMake(mapCenter, span)
      }
      
      set(newRegion) {
         latitude = newRegion.center.latitude
         longitude = newRegion.center.longitude
         spanLatitudeDelta = newRegion.span.latitudeDelta
         spanLongitudeDelta = newRegion.span.longitudeDelta
      }
   }
   
   override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
      super.init(entity: entity, insertIntoManagedObjectContext: context)
   }
   
   init(region:  MKCoordinateRegion, context: NSManagedObjectContext) {
      let entity = NSEntityDescription.entityForName("SavedRegion", inManagedObjectContext: context)
      super.init(entity: entity!, insertIntoManagedObjectContext: context)
      
      
   }
}