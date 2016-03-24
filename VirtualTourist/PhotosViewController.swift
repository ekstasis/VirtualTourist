//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/27/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation

class PhotosViewController:   UIViewController,
   UICollectionViewDataSource, UICollectionViewDelegate,
NSFetchedResultsControllerDelegate {
   
   @IBOutlet weak var stackView: UIStackView!
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var removeRefreshButton: UIButton!
   
   var pin: Pin!
   let mainContext = CoreDataStackManager.sharedInstance.managedObjectContext
   lazy var fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
   lazy var fileManager = NSFileManager.defaultManager()
   var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
   var removeMode = false
   let cellDimAlpha: CGFloat = 0.3
   
   // placement of waiting indicator should cover the collection view in the stackView
   var activityIndicatorFrame: CGRect {
      var frame = stackView.arrangedSubviews[1].frame
      frame.origin.y += stackView.frame.origin.y
      return frame
   }
   
   lazy var frc: NSFetchedResultsController = {
      
      let fetchRequest = NSFetchRequest(entityName: "Photo")
      fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
      fetchRequest.sortDescriptors = []
      
      let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainContext, sectionNameKeyPath: nil, cacheName: nil)
      frc.delegate = self
      return frc
   }()
   
   var indexesToBeInserted = [NSIndexPath]()
   var indexesToBeDeleted = [NSIndexPath]()
   var indexesToBeUpdated = [NSIndexPath]()
   var indexesSelected = [NSIndexPath]()
   
   // MARK:  View Lifecycle
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      activityIndicator.backgroundColor = UIColor.blueColor()
      activityIndicator.alpha = 0.8
      
      collectionView.allowsMultipleSelection = true
      collectionView.dataSource = self
      collectionView.delegate = self
      
      let layout = PhotoAlbumFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      collectionView.collectionViewLayout = layout
      
      do {
         try frc.performFetch()
      } catch let error as NSError {
         print(error)
      }
   }
   
   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)
      
      if frc.sections![0].numberOfObjects == 0 {
         startActivityIndicator()
      }
   }
   
   override func viewDidAppear(animated: Bool) {
      super.viewWillAppear(animated)
      
      removeRefreshButton.setTitle("New Collection", forState: .Normal)
      
      setUpMap()
   }
   
   override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      activityIndicator.frame = activityIndicatorFrame
   }
   
   func startActivityIndicator() {
      activityIndicator.frame = activityIndicatorFrame
      view.addSubview(activityIndicator)
      activityIndicator.startAnimating()
   }
   
   // MARK:  Main functions
   
   func setUpMap() {
      let mapCenter = pin.coordinate
      let span = MKCoordinateSpanMake(0.7, 0.7)
      mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
      mapView.addAnnotation(pin)
   }
   
   func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
      
      if !NSThread.isMainThread() {
         print("*** NOT MAIN THREAD ***")
      }
      
      // photo.filename is not nil if image successfully downloaded
      if let fileName = photo.fileName {
         
         let filePath = fileDirectory.URLByAppendingPathComponent(fileName).path!
         
         if let imageData = fileManager.contentsAtPath(filePath) {
            cell.imageView.image = UIImage(data: imageData)
         }
         
         cell.activityIndicator.stopAnimating()
      } else {
         cell.activityIndicator.startAnimating()
      }
   }
   
   // Dual-mode button:  Remove photos or Refresh collection
   @IBAction func removeOrRefreshButton(sender: AnyObject) {
      
      if removeMode {
         
         for indexPath in indexesSelected {
            let photo = frc.objectAtIndexPath(indexPath) as! Photo
            mainContext.deleteObject(photo)
         }
         
         indexesSelected = [NSIndexPath]()
         
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
         
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
         
      } else { // New Collection
         
         // Delete all photos and get new ones
         for photo in frc.fetchedObjects as! [Photo] {
            mainContext.deleteObject(photo)
         }
         
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
         
         //         getNewPhotos()
      }
   }
   
   func showAlert(errorString: String) {
      
      let alertController = UIAlertController(title: "Alert", message: errorString, preferredStyle: .Alert)
      let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
      alertController.addAction(action)
      
      dispatch_async(dispatch_get_main_queue()) {
         self.activityIndicator.stopAnimating()
         self.removeRefreshButton.enabled = true
         self.presentViewController(alertController, animated: true, completion: nil)
      }
   }
   
   // MARK: Collection View Delegate & DataSource
   
   func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      let numItemsInSection = frc.sections![0].numberOfObjects
      if numItemsInSection != 0 {
         activityIndicator.stopAnimating()
      }
      return numItemsInSection
   }
   
   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      
//      print("cellforitem at: \(indexPath.item)")
      
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
      
      // Protect against fetching new collection while still scrolling due to momentum
      guard !pin.photos.isEmpty else {
         return cell
      }
      
      let photo = frc.objectAtIndexPath(indexPath) as! Photo
      
      if let indexesForDeletion = collectionView.indexPathsForSelectedItems() {
         if indexesForDeletion.contains(indexPath) {
            cell.imageView.alpha = cellDimAlpha
         } else {
            cell.imageView.alpha = 1.0
         }
      }
      
      print("\(indexPath.item + 1): ", terminator: "")
      print(photo.objectID)
      
      configureCell(cell, photo: photo)
      return cell
   }
   
   func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
      
      removeMode = true
      removeRefreshButton.setTitle("Remove Photos", forState: .Normal)
      
      indexesSelected.append(indexPath)
      
//      print(indexPath.item)
      
      let photo = frc.objectAtIndexPath(indexPath) as! Photo
      ///
      photo.fileName = ""
   }
   
   func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
      
      let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
      
      cell.imageView.alpha = 1.0
      indexesSelected.removeAtIndex(indexesSelected.indexOf(indexPath)!)
      
      // If this was the last cell to be deselected, get out of remove mode
      if indexesSelected.isEmpty {
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
      }
   }
   
   // MARK: - Fetched Results Controller Delegate (lovingly inspired by ColorCollection)
   
   func controllerWillChangeContent(controller: NSFetchedResultsController) {
      indexesToBeInserted = [NSIndexPath]()
      indexesToBeDeleted = [NSIndexPath]()
      indexesToBeUpdated = [NSIndexPath]()
   }
   
   func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
      
//      print("didChangeObject:", terminator: "")
      switch type {
         
      case .Insert:
//         print(".Insert")
         indexesToBeInserted.append(newIndexPath!)
      case .Delete:
//         print(".Delete")
         indexesToBeDeleted.append(indexPath!)
      case .Update:
//         print(".Update \(indexPath)", terminator: "")
         indexesToBeUpdated.append(indexPath!)
      default:
         return
      }
   }
   
   func controllerDidChangeContent(controller: NSFetchedResultsController) {
      
      let batchUpdates = { () -> Void in
         
         for indexPath in self.indexesToBeInserted {
            self.collectionView.insertItemsAtIndexPaths([indexPath])
         }
         for indexPath in self.indexesToBeDeleted {
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
         }
         for indexPath in self.indexesToBeUpdated {
            self.collectionView.reloadItemsAtIndexPaths([indexPath])
         }
      }
      
      collectionView.performBatchUpdates(batchUpdates, completion: nil)
   }
}