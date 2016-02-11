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

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin!
    
    //    var selectedIndexes = [NSIndexPath]()
    //    var insertedIndexPaths: [NSIndexPath]!
    //    var deletedIndexPaths: [NSIndexPath]!
    //    var updatedIndexPaths: [NSIndexPath]!
    
    let sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpMap()
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard pin.photos.isEmpty else {
            return
        }
        
        // in client CH, get photo URLs and create Photos with them
        FlickrClient.sharedInstance.fetchPhotoPaths(pin) { paths, errorString in
            
            guard errorString == nil else {
                print(errorString)
                return
            }
            
            let _ = paths!.map { (path) -> Photo in
                Photo(filePath: path, pin: self.pin, context: self.sharedContext)
            }
            
            CoreDataStackManager.sharedInstance.saveContext()
        }
        
        // update CV in main thread?
    }
    
    func setUpMap() {
        let mapCenter = pin.coordinate
        let span = MKCoordinateSpanMake(3.0, 3.0)
        mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
        mapView.addAnnotation(pin)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.row]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, photo: photo)
        
        return cell
        
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        
        let fileDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        let filePath = fileDirectory.URLByAppendingPathComponent(photo.fileName).path
        let fileManager = NSFileManager.defaultManager()
        
        if let imageData = fileManager.contentsAtPath(filePath!) {
            // create image, set image on cell, return cell
            
        } else {
            
            let imageTask = FlickrClient.sharedInstance.imageDownloadTask(photo.filePath) { image, errorString in
                // imagedownload CH
            }
        }
    }
}