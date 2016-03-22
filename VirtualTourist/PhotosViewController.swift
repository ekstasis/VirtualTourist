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
                              UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
   
   @IBOutlet weak var stackView: UIStackView!
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var removeRefreshButton: UIButton!
   
   // the fetched results controller computed property is at end of file
   
   var pin: Pin!
   let sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext
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
      
      let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
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
      
      removeRefreshButton.setTitle("New Collection", forState: .Normal)
      activityIndicator.backgroundColor = UIColor.blueColor()
      activityIndicator.alpha = 0.8
      
      setUpMap()
   }
   
   // getNewPhotos needs frame of collection view for activity indicator, not available until after didAppear
   override func viewDidAppear(animated: Bool) {
      super.viewDidAppear(animated)

      if frc.sections![0].numberOfObjects == 0 {
//         getNewPhotos()
      }
   }
   
   // For activity indicator when rotating
   override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
      dispatch_async(dispatch_get_main_queue()) {
         self.activityIndicator.frame = self.activityIndicatorFrame
      }
      
   }
   
   // MARK:  Main functions
   
   
   
   func setUpMap() {
      let mapCenter = pin.coordinate
      let span = MKCoordinateSpanMake(0.7, 0.7)
      mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
      mapView.addAnnotation(pin)
   }
   
   func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
      
      let filePath = fileDirectory.URLByAppendingPathComponent(photo.fileName).path!
      
      if let imageData = fileManager.contentsAtPath(filePath) { // Image already downloaded
         cell.imageView.image = UIImage(data: imageData)
         
//      } else {  // Download image
         
//         cell.activityIndicator.startAnimating()
         
//         let imageTask = FlickrClient.sharedInstance.imageDownloadTask(photo.filePath) { imageData, errorString in
         
//            guard errorString == nil else {
//               if errorString != "cancelled" {  // we will get this error frequently during cell reuse
//                  self.showAlert(errorString!)
//               }
//               return
//            }
         
         
//            dispatch_async(dispatch_get_main_queue()) {
//               cell.activityIndicator.stopAnimating()
//               cell.imageView.image = image
//            }
//            
//            let image = UIImage(data: imageData!)!
//            let imageToBeSaved = UIImageJPEGRepresentation(image, 1.0)!
//            imageToBeSaved.writeToFile(filePath, atomically: true)
         }
         
         // This download should be cancelled if this cell is reused
//         cell.taskToCancelifCellIsReused = imageTask
      }
   
   // Dual-mode button:  Remove photos or Refresh collection
   @IBAction func removeOrRefreshButton(sender: AnyObject) {
      
      if removeMode {
         
         for indexPath in indexesSelected {
            let photo = frc.objectAtIndexPath(indexPath) as! Photo
            sharedContext.deleteObject(photo)
         }
         
         indexesSelected = [NSIndexPath]()
         
         CoreDataStackManager.sharedInstance.saveContext(sharedContext)
         
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
         
      } else { // New Collection
         
         // Delete all photos and get new ones
         for photo in frc.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
         }
         
         CoreDataStackManager.sharedInstance.saveContext(sharedContext)
         
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
      return numItemsInSection
   }
   
   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
      
      // Protect against fetching new collection while still scrolling due to momentum
      guard !pin.photos.isEmpty else {
         return cell
      }
      
//      let photo = pin.photos[indexPath.item]
      let photo = frc.objectAtIndexPath(indexPath) as! Photo
      
      if let indexesForDeletion = collectionView.indexPathsForSelectedItems() {
         if indexesForDeletion.contains(indexPath) {
            cell.imageView.alpha = cellDimAlpha
         } else {
            cell.imageView.alpha = 1.0
         }
      }
      
      configureCell(cell, photo: photo)
      return cell
   }
   
   func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
      
      removeMode = true
      removeRefreshButton.setTitle("Remove Photos", forState: .Normal)
      
      let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
      cell.imageView.alpha = cellDimAlpha
      indexesSelected.append(indexPath)
      
      let photo = frc.objectAtIndexPath(indexPath) as! Photo
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
      
      switch type {
         
      case .Insert:
         indexesToBeInserted.append(newIndexPath!)
      case .Delete:
         indexesToBeDeleted.append(indexPath!)
      case .Update:
         print(".Update in didChangeObject")
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