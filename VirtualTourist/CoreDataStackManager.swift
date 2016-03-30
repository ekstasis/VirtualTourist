//
//  CoreDataStackManager.swift
//  FavoriteActors
//
//  Created by Jason on 3/10/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//


import Foundation
import CoreData

private let SQLITE_FILE_NAME = "virtual_tourist.sqlite"

var testCounter = 0
var x = "delete me"

/*
*  Adapted from Udacity examples
*/
class CoreDataStackManager {
   
   static let sharedInstance = CoreDataStackManager()
   
   lazy var applicationDocumentsDirectory: NSURL = {
      
      let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
      return urls[urls.count-1]
   }()
   
   lazy var managedObjectModel: NSManagedObjectModel = {
      
      let modelURL = NSBundle.mainBundle().URLForResource("VirtualTourist", withExtension: "momd")!
      return NSManagedObjectModel(contentsOfURL: modelURL)!
   }()
   
   lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
      
      let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
      let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
      
      var failureReason = "There was an error creating or loading the application's saved data."
      do {
         try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
      } catch {
         // Report any error we got.
         var dict = [String: AnyObject]()
         dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
         dict[NSLocalizedFailureReasonErrorKey] = failureReason
         
         dict[NSUnderlyingErrorKey] = error as NSError
         let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
         abort()
      }
      
      return coordinator
   }()
   
   lazy var managedObjectContext: NSManagedObjectContext = {
      let coordinator = self.persistentStoreCoordinator
      var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
      managedObjectContext.persistentStoreCoordinator = coordinator
      return managedObjectContext
   }()
   
   func createPrivateMOC() -> NSManagedObjectContext {
      let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      moc.parentContext = managedObjectContext
      return moc
   }
   
   // MARK: - Core Data Saving support
   
   // Recursive save for child contexts
   func saveContext(context: NSManagedObjectContext) {
      
      context.performBlockAndWait() {
         if context.hasChanges {
            do {
               try context.save()
            } catch let error as NSError {
               NSLog("Unresolved error \(error), \(error.userInfo)")
               abort()
            }
            
            if let parent = context.parentContext {
               self.saveContext(parent)
            }
         }
      }
   }
}