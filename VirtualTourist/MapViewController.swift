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
   
   // MARK: View Controller Functions
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationItem.rightBarButtonItem = editButtonItem()
      mapView.delegate = self
      
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
      longPressRecognizer.minimumPressDuration = 1.0
      mapView.addGestureRecognizer(longPressRecognizer)
      getSavedRegion()
   }
   
   // Use persisted map region otherwise use iOS default
   override func viewWillLayoutSubviews() {
      if let region = savedRegion?.region {
         mapView.setRegion(region, animated: true)
      } else {
         savedRegion = SavedRegion(region: mapView.region, context: mainContext)
      }
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
         FlickrClient.sharedInstance.fetchPhotos(droppedPin)
         segueToAlbumView(droppedPin)
         
      default:
         return
      }
   }
   
   func segueToAlbumView(pin: Pin) {
      let photosVC = storyboard?.instantiateViewControllerWithIdentifier("Photos") as! PhotosViewController
      photosVC.pin = pin
      navigationController?.pushViewController(photosVC, animated: true)
   }
   
   // MARK: Region Saving and Loading
   
   // Called by mapView regionDidChange()
   func saveCurrentMapRegion() {
      if let regionToBeSaved = savedRegion {
         regionToBeSaved.region = mapView.region
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
      }
   }
   
   func getSavedRegion() { // From Core Data on App Load
      
      let fetchRequest = NSFetchRequest(entityName: "SavedRegion")
      do {
         let savedRegions = try mainContext.executeFetchRequest(fetchRequest) as! [SavedRegion]
         if !savedRegions.isEmpty {
            savedRegion = savedRegions[0]
         }
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
   
   // Saves current region to Core Data
   func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
         saveCurrentMapRegion()
   }
   
   func mapViewDidFinishLoadingMap(mapView: MKMapView) {
      populatePins()
   }
}