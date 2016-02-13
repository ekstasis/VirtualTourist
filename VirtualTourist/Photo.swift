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
    @NSManaged var filePath: String
    @NSManaged var fileName: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(filePath: String, pin: Pin, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.filePath = filePath
        self.pin = pin
        
        let url = NSURL(string: filePath)!
        fileName = url.lastPathComponent!
    }
    
    deinit {
        let fileManager = NSFileManager.defaultManager()
        let directory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        let fileToDelete = directory.URLByAppendingPathComponent(fileName)
        
        print("deinit: \(fileName)")
        print(filePath)
        
        do {
            try fileManager.removeItemAtURL(fileToDelete)
            print("trying to delete")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
