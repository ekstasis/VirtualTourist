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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    var pin: Pin!
    let sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext
    var editMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpMap()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        activityIndicator.backgroundColor = UIColor.redColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.allowsMultipleSelection = true
        
        editButton.setTitle("New Collection", forState: .Normal)
        
        guard pin.photos.isEmpty else {
            return
        }
        
//        let frame = CGRect(x: 0, y: 110, width: 320, height: 440)
//        activityIndicator.frame = frame
        
        activityIndicator.frame = collectionView.frame
        print(collectionView.frame)
        print(collectionView.bounds)
        print(view.frame)
        print(view.bounds)
        print(activityIndicator.frame)
        
        getNewPhotos()
    }
    
    func getNewPhotos() {
        
        editButton.enabled = false
        
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        FlickrClient.sharedInstance.fetchPhotoPaths(pin) { paths, errorString in
            
            guard errorString == nil else {
                print(errorString)
                return
            }
            
            print("fetched paths")
            
            let _ = paths!.map { (path) -> Photo in
                Photo(filePath: path, pin: self.pin, context: self.sharedContext)
            }
            
            CoreDataStackManager.sharedInstance.saveContext()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.activityIndicator.stopAnimating()
                self.editButton.enabled = true
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
        
        if editMode {
            ///////// handle optional?
            let indexesForDeletion = collectionView.indexPathsForSelectedItems()!
            for index in indexesForDeletion {
                sharedContext.deleteObject(pin.photos[index.item])
                let cell = collectionView.cellForItemAtIndexPath(index) as! PhotoCollectionViewCell
                cell.imageView.alpha = 1.0
            }
            
            CoreDataStackManager.sharedInstance.saveContext()
            collectionView.deleteItemsAtIndexPaths(indexesForDeletion)
            
            editMode = false
            editButton.setTitle("New Collection", forState: .Normal)
            
        } else {
            for photo in pin.photos {
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance.saveContext()
            getNewPhotos()
        }
        
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        
        let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        let filePath = fileDirectory.URLByAppendingPathComponent(photo.fileName).path!
        let fileManager = NSFileManager.defaultManager()
        
        if let imageData = fileManager.contentsAtPath(filePath) {
            // create image, set image on cell, return cell
            cell.imageView.image = UIImage(data: imageData)
            
        } else {
            
            cell.activityIndicator.startAnimating()
            
            let imageTask = FlickrClient.sharedInstance.imageDownloadTask(photo.filePath) { imageData, errorString in
                // Save Image
                
                guard errorString == nil else {
                    print(errorString)
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
        
        print("select")
        
        editMode = true
        editButton.setTitle("Remove Photos", forState: .Normal)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.alpha = 0.3
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        print("deselect")
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        cell.imageView.alpha = 1.0
        
        if collectionView.indexPathsForSelectedItems()!.isEmpty {
            editMode = false
            editButton.setTitle("New Collection", forState: .Normal)
        }
    }
   
}