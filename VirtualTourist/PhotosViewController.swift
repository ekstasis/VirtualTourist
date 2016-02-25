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

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var removeRefreshButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    let sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext
    
    var removeMode = false
    var pin: Pin!
    
    // placement of waiting indicator should cover the collection view in the stackView
    var activityIndicatorFrame: CGRect {
        
        var frame = stackView.arrangedSubviews[1].frame
        frame.origin.y += stackView.frame.origin.y
        
        return frame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpMap()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.allowsMultipleSelection = true
        removeRefreshButton.setTitle("New Collection", forState: .Normal)
        
        activityIndicator.color = UIColor.blackColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            getNewPhotos()
        }
    }
    
    // For device rotation
    override func viewDidLayoutSubviews() {
        activityIndicator.frame = activityIndicatorFrame
    }
    
    func getNewPhotos() {
        
        removeRefreshButton.enabled = false
        
        activityIndicator.frame = activityIndicatorFrame
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        FlickrClient.sharedInstance.fetchPhotoPaths(pin) { paths, errorString in
            
            guard errorString == nil else {
                if errorString == "cancelled" {  // we will get this error frequently during cell reuse
                    return
                } else {
                    self.showAlert(errorString!)
                }
                return
            }
            
            // Create Photos from flickr API JSON results
            
            let privateMOC = CoreDataStackManager.sharedInstance.newPrivateQueueContext()
            
            privateMOC.performBlock {
                let _ = paths!.map { (path) -> Photo in
                    Photo(filePath: path, pin: self.pin, context: privateMOC)
                }
                
                CoreDataStackManager.sharedInstance.saveContext(privateMOC)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.activityIndicator.stopAnimating()
                self.removeRefreshButton.enabled = true
                self.collectionView.reloadData()
            }
        }
    }
    
    func setUpMap() {
        let mapCenter = pin.coordinate
        let span = MKCoordinateSpanMake(3.0, 3.0)
        mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
        mapView.addAnnotation(pin)
    }
    
    @IBAction func removeOrRefreshButton(sender: AnyObject) {
        
        if removeMode {
            let indexesForDeletion = collectionView.indexPathsForSelectedItems()!
            for index in indexesForDeletion {
                sharedContext.deleteObject(pin.photos[index.item])
                let cell = collectionView.cellForItemAtIndexPath(index) as! PhotoCollectionViewCell
                cell.imageView.alpha = 1.0
            }
            
            CoreDataStackManager.sharedInstance.saveContext(sharedContext)
            collectionView.deleteItemsAtIndexPaths(indexesForDeletion)
            
            removeMode = false
            removeRefreshButton.setTitle("New Collection", forState: .Normal)
            
        } else {
            
            // Delete all photos and get new ones
            for photo in pin.photos {
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance.saveContext(sharedContext)
            
            getNewPhotos()
        }
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        
        let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        let filePath = fileDirectory.URLByAppendingPathComponent(photo.fileName).path!
        let fileManager = NSFileManager.defaultManager()
        
        // Image already downloaded
        if let imageData = fileManager.contentsAtPath(filePath) {
            cell.imageView.image = UIImage(data: imageData)
            
        } else {  // Download image
            
            cell.activityIndicator.startAnimating()
            
            let imageTask = FlickrClient.sharedInstance.imageDownloadTask(photo.filePath) { imageData, errorString in
                
                guard errorString == nil else {
                    
                    if errorString == "cancelled" {  // we will get this error frequently during cell reuse
                        return
                    } else {
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
            
            // This task should be cancelled if this cell is reused
            cell.taskToCancelifCellIsReused = imageTask
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, photo: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        removeMode = true
        removeRefreshButton.setTitle("Remove Photos", forState: .Normal)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.alpha = 0.3
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