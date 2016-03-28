//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

   var window: UIWindow?
   var mapVC: MapViewController! = MapViewController()
   
   func applicationWillResignActive(application: UIApplication) {
      print("resign active")
      mapVC.saveCurrentMapRegion()
   }

}
