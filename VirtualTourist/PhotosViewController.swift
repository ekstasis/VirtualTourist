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
                              UICollectionViewDataSource, UICollectionViewDelegate {
   
   @IBOutlet weak var stackView: UIStackView!
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var removeRefreshButton: UIButton!
   
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
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      collectionView.allowsMultipleSelection = true
      collectionView.dataSource = self
      collectionView.delegate = self
      
      let layout = PhotoAlbumFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      collectionView.collectionViewLayout = layout
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
      
      if pin.photos.isEmpty {
         getNewPhotos()
      }
   }
   
   // For activity indicator when rotating
   override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
      dispatch_async(dispatch_get_main_queue()) {
         self.activityIndicator.frame = self.activityIndicatorFrame
      }
      
   }
   
   func getNewPhotos() {
      
      removeRefreshButton.enabled = false
      
      activityIndicator.frame = activityIndicatorFrame
      view.addSubview(activityIndicator)
      activityIndicator.startAnimating()
      
      // Download API JSON image paths
      FlickrClient.sharedInstance.fetchPhotoPaths(pin) { paths, availablePages, errorString in
         
         guard errorString == nil else {
            self.showAlert(errorString!)
            return
         }
         
         // Create Photos from flickr API JSON image paths
         
         // We are not on the main thread, but no need to create a private context (blocking UI is OK)
         self.sharedContext.performBlock {
            
            self.pin.availablePages = availablePages!
            
            let _ = paths!.map { (path) -> Photo in
               Photo(filePath: path, pin: self.pin, context: self.sharedContext)
            }
            
            CoreDataStackManager.sharedInstance.saveContext()
         }
         
         dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
            self.removeRefreshButton.enabled = true
            self.collectionView.reloadData()
            self.collectionView.setContentOffset(CGPoint.zero, animated: true)
         }
      }
   }
   
   func setUpMap() {
      let mapCenter = pin.coordinate
      let span = MKCoordinateSpanMake(0.7, 0.7)
      mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
      mapView.addAnnotation(pin)
   }
   
   // Dual-mode button:  Remove photos or Refresh collection
   @IBAction func removeOrRefreshButton(sender: AnyObject) {
      
      if removeMode {
         
         let indexesForDeletion = collectionView.indexPathsForSelectedItems()!
         
         for index in indexesForDeletion {
            sharedContext.deleteObject(pin.photos[index.item])
         }
         
         CoreDataStackManager.sharedInstance.saveContext()
         
         collectionView.deleteItemsAtIndexPaths(indexesForDeletion)
         
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
         
      } else { // New Collection
         
         // Delete all photos and get new ones
         for photo in pin.photos {
            sharedContext.deleteObject(photo)
         }
         CoreDataStackManager.sharedInstance.saveContext()
         getNewPhotos()
      }
   }
   
   func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return pin.photos.count
   }
   
   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
      
      // Protect against fetching new collection while still scrolling due to momentum
      guard !pin.photos.isEmpty else {
         return cell
      }
      
      let photo = pin.photos[indexPath.item]
      
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
   
   func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
      
      let filePath = fileDirectory.URLByAppendingPathComponent(photo.fileName).path!
      
      if let imageData = fileManager.contentsAtPath(filePath) { // Image already downloaded
         cell.imageView.image = UIImage(data: imageData)
         
      } else {  // Download image
         
         cell.activityIndicator.startAnimating()
         
         let imageTask = FlickrClient.sharedInstance.imageDownloadTask(photo.filePath) { imageData, errorString in
            
            guard errorString == nil else {
               if errorString != "cancelled" {  // we will get this error frequently during cell reuse
                  self.showAlert(errorString!)
               }
               return
            }
            
            let image = UIImage(data: imageData!)!
            
            dispatch_async(dispatch_get_main_queue()) {
               cell.activityIndicator.stopAnimating()
               cell.imageView.image = image
            }
            
            let imageToBeSaved = UIImageJPEGRepresentation(image, 1.0)!
            imageToBeSaved.writeToFile(filePath, atomically: true)
         }
         
         // This download should be cancelled if this cell is reused
         cell.taskToCancelifCellIsReused = imageTask
      }
   }
   
   func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
      
      removeMode = true
      removeRefreshButton.setTitle("Remove Photos", forState: .Normal)
      
      let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
      cell.imageView.alpha = cellDimAlpha
   }
   
   func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
      
      let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell

      cell.imageView.alpha = 1.0
      
      // If this was the last cell to be deselected, get out of remove mode
      if collectionView.indexPathsForSelectedItems()!.isEmpty {
         removeMode = false
         removeRefreshButton.setTitle("New Collection", forState: .Normal)
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
}