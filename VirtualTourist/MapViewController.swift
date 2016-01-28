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
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = editButtonItem()
        
        mapView.delegate = self
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        
        setInitialLocation()
    }
    
    func dropPin(longPressRecognizer: UILongPressGestureRecognizer) {
        guard longPressRecognizer.state == .Began else {
            return
        }
        
        let tapLocation = longPressRecognizer.locationInView(mapView)
        let mapCoordinate = mapView.convertPoint(tapLocation, toCoordinateFromView: mapView)
        
        let pin = Pin(location: mapCoordinate, context: sharedContext)
        mapView.addAnnotation(pin)
    }
    
    // If first time running app, get user's location, otherwise used saved location
    func setInitialLocation() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let regionData = defaults.objectForKey("Region Data") as? NSDictionary {
            let latitude = regionData["Latitude"] as! CLLocationDegrees
            let longitude = regionData["Longitude"] as! CLLocationDegrees
            let spanLatitudeDelta = regionData["Latitude Delta"] as! CLLocationDegrees
            let spanLongitudeDelta = regionData["Longitude Delta"] as! CLLocationDegrees
            let mapCenter = CLLocationCoordinate2DMake(latitude, longitude)
            let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
            
            mapView.region = MKCoordinateRegion(center: mapCenter, span: span)
            
        } else {  // Save the maps default initial region (from iPhone international settings)
            saveCurrentMapRegion(mapView.region)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveCurrentMapRegion(mapView.region)
    }
    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        
//        var pinView: MKAnnotationView!
//        
//        if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("Pin") {
//            pinView.annotation = annotation
//        } else {
//            pinView = MKAnnotationView()
//            pinView.annotation = annotation
//        }
//        
//        return pinView
//    }
    
    func saveCurrentMapRegion(region: MKCoordinateRegion) {
        let mapCenter = region.center
        let span = region.span
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let locationDictionary =
        [
            "Latitude" : mapCenter.latitude,
            "Longitude" : mapCenter.longitude,
            "Latitude Delta" : span.latitudeDelta,
            "Longitude Delta" : span.longitudeDelta
        ]
        
        defaults.setObject(locationDictionary, forKey: "Region Data")
        
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            print("if editing")
        } else {
            print("not editing")
        }
    }
    

}