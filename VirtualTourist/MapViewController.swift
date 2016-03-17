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
   
   let sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationItem.rightBarButtonItem = editButtonItem()
      
      mapView.delegate = self
      
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
      longPressRecognizer.minimumPressDuration = 1.0
      mapView.addGestureRecognizer(longPressRecognizer)
   }
   
   override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      setInitialLocation()
      populatePins()
   }
   
   // Retrieve persisted map center and zoom
   func setInitialLocation() {
      
      let defaults = NSUserDefaults.standardUserDefaults()
      
      if let regionData = defaults.objectForKey("Region Data") as? NSDictionary {
         let latitude = regionData["Latitude"] as! CLLocationDegrees
         let longitude = regionData["Longitude"] as! CLLocationDegrees
         let spanLatitudeDelta = regionData["Latitude Delta"] as! CLLocationDegrees
         let spanLongitudeDelta = regionData["Longitude Delta"] as! CLLocationDegrees
         let mapCenter = CLLocationCoordinate2DMake(latitude, longitude)
         let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
         let region = MKCoordinateRegionMake(mapCenter, span)
         
         print("\nsetInitialLocation(): ")
//         print("   LongitudeDelta loaded from UserDefaults = \(spanLongitudeDelta)")
//         print("   regionThatFits.LongitudeDelta = \(mapView.regionThatFits(region).span.longitudeDelta)")
         
         print(region)
         print(mapView.regionThatFits(region))
         
         print("\n- setInitialLocation() about to setRegion -")
         mapView.setRegion(region, animated: true)
         
         print("\nsetInitialLocation(): ")
         print("   mapView's LonDelta now equals = \(mapView.region.span.longitudeDelta)")
         
      } else {
         // Save the map's default initial region (from iPhone international settings)
         saveCurrentMapRegion()
      }
   }
   
   // Fetch pins from Core Data
   func populatePins() {
      
      let fetchRequest = NSFetchRequest(entityName: "Pin")
      var pins = [Pin]()
      
      do {
         pins = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
      } catch {
         return
      }
      
      mapView.addAnnotations(pins)
   }
   
   func dropPin(longPressRecognizer: UILongPressGestureRecognizer) {
      
      guard longPressRecognizer.state == .Began else {
         return
      }
      
      let tapLocation = longPressRecognizer.locationInView(mapView)
      let mapCoordinate = mapView.convertPoint(tapLocation, toCoordinateFromView: mapView)
      let pin = Pin(location: mapCoordinate, context: sharedContext)
      
      CoreDataStackManager.sharedInstance.saveContext()
      
      mapView.addAnnotation(pin)
   }
   
   // Continually persist map center
   func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      print("\nregionDidChange:")
      saveCurrentMapRegion()
   }
   
   // Handles pin deletion and transition to photo album depending on whether editing or not
   func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
      
      mapView.deselectAnnotation(view.annotation, animated: true)
      
      let pin = view.annotation as! Pin
      
      if editing { // remove annotation and delete CD object
         mapView.removeAnnotation(pin)
         sharedContext.deleteObject(pin)
         CoreDataStackManager.sharedInstance.saveContext()
         return
         
      } else { // Present photo collection
         let photosVC = storyboard?.instantiateViewControllerWithIdentifier("Photos") as! PhotosViewController
         photosVC.pin = pin
         navigationController?.pushViewController(photosVC, animated: true)
      }
   }
   
   func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
      
      let annotationView: MKAnnotationView
      
      if let view = mapView.dequeueReusableAnnotationViewWithIdentifier("Pin") {
         annotationView = view
      } else {
         annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
      }
      
      annotationView.canShowCallout = false
      
      return annotationView
   }
   
   // Persist map zoom and center in user defaults
   func saveCurrentMapRegion() {
      
      print("   saveCurrentMapRegion(): ")
//      print("      mapView.region's LongDelta now equals = \(mapView.region.span.longitudeDelta)")
//      print("      mapView.regionThatFits LongDelta now equals = \(mapView.regionThatFits(mapView.region).span.longitudeDelta)")
      
      let region = mapView.regionThatFits(mapView.region)
      let mapCenter = region.center
      let span = region.span
      let defaults = NSUserDefaults.standardUserDefaults()
      
         print(region)
         print(mapView.regionThatFits(region))
      
      let locationDictionary =
      [
         "Latitude" : mapCenter.latitude,
         "Longitude" : mapCenter.longitude,
         "Latitude Delta" : span.latitudeDelta,
         "Longitude Delta" : span.longitudeDelta
      ]
      
      print("      LongitudeDelta saved to defaults = \(locationDictionary["Longitude Delta"]!)")
      
      defaults.setObject(locationDictionary, forKey: "Region Data")
   }
}
