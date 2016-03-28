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
   
   // Placement of waiting indicator should cover the collection view in the stackView
   var activityIndicatorFrame: CGRect {
      var frame = stackView.arrangedSubviews[1].frame
      frame.origin.y += stackView.frame.origin.y
      return frame
   }
   
   lazy var frc: NSFetchedResultsController = {
      let fetchRequest = NSFetchRequest(entityName: "Photo")
      fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
      let sortDesc = NSSortDescriptor.init(key: "imageURL", ascending: true)
      fetchRequest.sortDescriptors = [sortDesc]
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
      
      setUpMap()
      
      collectionView.dataSource = self
      collectionView.delegate = self
      
      do {
         try frc.performFetch()
      } catch let error as NSError {
         showAlert(error.localizedDescription)
      }
      
      let layout = PhotoAlbumFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      collectionView.collectionViewLayout = layout
      
      activityIndicator.backgroundColor = UIColor.blueColor()
      activityIndicator.alpha = 0.8
      
      // Locations with no photos.  Will show an alert.
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "noPhotoAlert", name: NoPhotosNotification, object: nil)
      // We need to know it's OK to delete Photos and not orphan image files
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedDownloadingImages", name: AllFilesWrittenNotification, object: nil)
   }
   
   // Called by notification to indicate it's OK to delete photos
   
   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)
      
      view.addSubview(activityIndicator)
      
      removeRefreshButton.setTitle("New Collection", forState: .Normal)
      
      // Still downloading Flickr image URLs
      if frc.sections![0].numberOfObjects == 0 {
         removeRefreshButton.enabled = false
         startActivityIndicator()
         
      }
      
      if pin.availablePages == 0 {
         noPhotoAlert()
      }
   }
   
   // Activity Indicator resizing, eg for rotation
   override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      activityIndicator.frame = activityIndicatorFrame
   }
   
   // MARK:  Main functions
   
   func startActivityIndicator() {
      activityIndicator.frame = activityIndicatorFrame
      activityIndicator.startAnimating()
   }
   
   func setUpMap() {
      let mapCenter = pin.coordinate
      let span = MKCoordinateSpanMake(0.7, 0.7)
      mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
      mapView.addAnnotation(pin)
   }
   
   func finishedDownloadingImages() {
      removeRefreshButton.enabled = true
   }
   
   func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
      
      // Check if photo is marked for deletion
      if let _ = indexesSelected.indexOf(indexPath) {
         cell.alpha = cellDimAlpha
      } else {
         cell.alpha = 1.0
      }
      
      let photo = frc.objectAtIndexPath(indexPath) as! Photo
      
      // Do we have an image yet?  photo.filename is not nil if image successfully downloaded
      if let fileName = photo.fileName {
         
         let filePath = fileDirectory.URLByAppendingPathComponent(fileName).path!
         
         if let imageData = fileManager.contentsAtPath(filePath) {
            cell.imageView.image = UIImage(data: imageData)
         } else {
            print("Error: No image file at \(filePath)")
         }
         
         cell.activityIndicator.stopAnimating()
         
      } else {
         cell.activityIndicator.startAnimating()  // Still downloading image
      }
   }
   
   func updateRefreshButton() {
      
      if indexesSelected.isEmpty {
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
      } else {
         removeMode = true
         removeRefreshButton.setTitle("Remove", forState: .Normal)
      }
   }
   
   // Dual-mode button:  Remove photos or Refresh collection
   @IBAction func removeOrRefreshButton(sender: AnyObject) {
      if removeMode {
         removePhotos()
      } else {
         newCollection()
      }
   }
   
   func removePhotos() {
      
      for indexPath in indexesSelected {
         let photo = frc.objectAtIndexPath(indexPath) as! Photo
         mainContext.deleteObject(photo)
      }
      
      CoreDataStackManager.sharedInstance.saveContext(mainContext)
      
      removeMode = false
      removeRefreshButton.setTitle("New Collection", forState: .Normal)
      indexesSelected = [NSIndexPath]()
   }
   
   func newCollection() {
      
      removeRefreshButton.enabled = false
      
      for photo in frc.fetchedObjects as! [Photo] {
         mainContext.deleteObject(photo)
      }
      
      CoreDataStackManager.sharedInstance.saveContext(mainContext)
      
      startActivityIndicator()
      
      FlickrClient.sharedInstance.fetchPhotos(pin)
      
      do {
         try frc.performFetch()
      } catch let error as NSError {
         showAlert(error.localizedDescription)
      }
   }
   
   func noPhotoAlert() {
      showAlert("There are no photos for this location")
   }
   
   func showAlert(errorString: String) {
      
      self.activityIndicator.stopAnimating()
      
      let alertController = UIAlertController(title: "I'm Every So Sorry But . . .", message: errorString, preferredStyle: .Alert)
      let action = UIAlertAction(title: "Forgive Me", style: .Default) { alert in
         self.navigationController?.popViewControllerAnimated(true)
      }
      alertController.addAction(action)
      
      self.presentViewController(alertController, animated: true, completion: nil)
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
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
      configureCell(cell, atIndexPath: indexPath)
      return cell
   }
   
   func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
      
      let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
      
      if let index = indexesSelected.indexOf(indexPath) {
         indexesSelected.removeAtIndex(index)
      } else {
         indexesSelected.append(indexPath)
      }
      
      configureCell(cell, atIndexPath: indexPath)
      
      updateRefreshButton()
   }
   
   // MARK:  Fetched Results Controller Delegate
   
   func controllerWillChangeContent(controller: NSFetchedResultsController) {
      indexesToBeInserted = [NSIndexPath]()
      indexesToBeDeleted = [NSIndexPath]()
      indexesToBeUpdated = [NSIndexPath]()
   }
   
   func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
      
      switch type {
      case .Insert:
         indexesToBeInserted.append(newIndexPath!)
         let photo = anObject as! Photo
      case .Delete:
         indexesToBeDeleted.append(indexPath!)
      case .Update:
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