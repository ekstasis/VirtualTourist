//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
   
   @IBOutlet weak var mapView: MKMapView!
   
   var droppedPin: Pin!
   var savedRegion: SavedRegion!
   let mainContext = CoreDataStackManager.sharedInstance.managedObjectContext
   var mapShouldLoad = true
   
   // MARK: View Controller Functions
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
      delegate.mapVC = self
      
      navigationItem.rightBarButtonItem = editButtonItem()
      mapView.delegate = self
      
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
      longPressRecognizer.minimumPressDuration = 1.0
      mapView.addGestureRecognizer(longPressRecognizer)
   }
   
   override func viewDidAppear(animated: Bool) {
      super.viewDidAppear(animated)
      
      // load region at this stage for correct map frame, but only do it once
      if mapShouldLoad {
         loadRegion()
      }
      mapShouldLoad = false
   }
   
   // MARK: Main Functions
   
   func populatePins() {
      
      let fetchRequest = NSFetchRequest(entityName: "Pin")
      
      do {
         let pins = try mainContext.executeFetchRequest(fetchRequest) as! [Pin]
         mapView.addAnnotations(pins)
      } catch let error as NSError {
         print(error)
      }
   }
   
   // Pin creation, dragging, prefetching, and auto segue to album view
   func dropPin(longPressRecognizer: UILongPressGestureRecognizer) {
      
      guard !editing else {  // don't create pins when you should be deleting them instead
         return
      }
      
      let tapLocation = longPressRecognizer.locationInView(mapView)
      let mapCoordinate = mapView.convertPoint(tapLocation, toCoordinateFromView: mapView)
      
      switch longPressRecognizer.state {
         
      case .Began:
         droppedPin = Pin(location: mapCoordinate, context: mainContext)
         mapView.addAnnotation(droppedPin)
         
      case .Changed:
         droppedPin.coordinate = mapCoordinate
         
      case .Ended:
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
         
         FlickrClient.sharedInstance.fetchPhotos(droppedPin) { errorString in
            
            if let error = errorString {
               self.showAlert(error)
               
            } else {
//               segueToAlbumView(droppedPin)
            }
         }
      default:
         return
      }
   }
   
   func segueToAlbumView(pin: Pin) {
      let photosVC = storyboard?.instantiateViewControllerWithIdentifier("Photos") as! PhotosViewController
      photosVC.pin = pin
      navigationController?.pushViewController(photosVC, animated: true)
   }
   
   func showAlert(errorString: String) {
      
      let alert = UIAlertController.create(errorString) { _ in
         
//         self.mainContext.performBlock() {
//            self.mapView.removeAnnotation(self.droppedPin)
//            self.mainContext.deleteObject(self.droppedPin)
//            CoreDataStackManager.sharedInstance.saveContext(self.mainContext)
//         }
      }
      alert.present()
   }
   
   // MARK: Region Saving and Loading
   
   // Called by App Delegate Will Resign Active
   func saveCurrentMapRegion() {
      savedRegion.region = mapView.region
      CoreDataStackManager.sharedInstance.saveContext(mainContext)
   }
   
   
   func loadRegion() { // From Core Data on App Load
      
      let fetchRequest = NSFetchRequest(entityName: "SavedRegion")
      
      do {
         let savedRegions = try mainContext.executeFetchRequest(fetchRequest) as! [SavedRegion]
         
         if !savedRegions.isEmpty {
            savedRegion = savedRegions[0]
            mapView.region = savedRegion.region
         } else {
            savedRegion = SavedRegion(context: mainContext)
            savedRegion.region = mapView.region
         }
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
         
      } catch let error as NSError {
         print(error)
      }
   }
   
   // MARK: Map Delegate
   
   // Handles pin deletion or transition to photo album depending on whether editing or not
   func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
      
      mapView.deselectAnnotation(view.annotation, animated: true)
      
      let pin = view.annotation as! Pin
      
      if editing { // remove annotation and delete CD object
         mapView.removeAnnotation(pin)
         mainContext.deleteObject(pin)
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
         return
         
      } else { // Present photo collection
         segueToAlbumView(pin)
      }
   }
   
   func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
      
      let annotationView: MKPinAnnotationView
      
      if let view = mapView.dequeueReusableAnnotationViewWithIdentifier("Pin") {
         annotationView = view as! MKPinAnnotationView
      } else {
         annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
         annotationView.animatesDrop = true
         annotationView.canShowCallout = false
      }
      
      annotationView.draggable = true
      return annotationView
   }
   
   func mapViewDidFinishLoadingMap(mapView: MKMapView) {
      populatePins()
   }
}