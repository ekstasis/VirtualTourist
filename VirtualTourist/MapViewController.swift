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
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationItem.rightBarButtonItem = editButtonItem()
      mapView.delegate = self
      
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
      longPressRecognizer.minimumPressDuration = 1.0
      mapView.addGestureRecognizer(longPressRecognizer)
      getSavedRegion()
      
   }
   
   override func viewWillLayoutSubviews() {
      if let region = savedRegion?.region {
         mapView.setRegion(region, animated: true)
      } else {
         savedRegion = SavedRegion(region: mapView.region, context: mainContext)
      }
   }
   
   func getSavedRegion() {
      
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
   
   // Fetch pins from Core Data
   func populatePins() {
      
      let fetchRequest = NSFetchRequest(entityName: "Pin")
      
      do {
         let pins = try mainContext.executeFetchRequest(fetchRequest) as! [Pin]
         mapView.addAnnotations(pins)
      } catch let error as NSError {
         print(error)
      }
   }
   
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
   
   // Continually persist map center
   func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      saveCurrentMapRegion()
   }
   
   func mapViewDidFinishLoadingMap(mapView: MKMapView) {
      populatePins()
   }
   
   // Handles pin deletion and transition to photo album depending on whether editing or not
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
   
   func segueToAlbumView(pin: Pin) {
         let photosVC = storyboard?.instantiateViewControllerWithIdentifier("Photos") as! PhotosViewController
         photosVC.pin = pin
         navigationController?.pushViewController(photosVC, animated: true)
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
   
   // Persist map zoom and center in user defaults
   func saveCurrentMapRegion() {
      if let regionToBeSaved = savedRegion {
         regionToBeSaved.region = mapView.region
         CoreDataStackManager.sharedInstance.saveContext(mainContext)
      }
   }
   
   
}