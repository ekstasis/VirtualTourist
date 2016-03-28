//
//  Photo.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
   
   @NSManaged var pin: Pin
   @NSManaged var imageURL: String
   @NSManaged var fileName: String?
   
   override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
      super.init(entity: entity, insertIntoManagedObjectContext: context)
   }
   
   init(imageURL: String, pin: Pin, context: NSManagedObjectContext) {
      let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
      super.init(entity: entity!, insertIntoManagedObjectContext: context)
      
      self.imageURL = imageURL
      self.pin = pin
   }
   
   override func prepareForDeletion() {
      
      let fileManager = NSFileManager.defaultManager()
      let directory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
      
      if let file = fileName {
         
         let fileToDelete = directory.URLByAppendingPathComponent(file)
         do {
            try fileManager.removeItemAtURL(fileToDelete)
         } catch let error as NSError {
            print(error)
         }
      }
   }
}
