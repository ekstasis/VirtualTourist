//
//  Alert.swift
//  OnTheMap
//
//  Created by Dolemite on 1/2/16.
//  Copyright © 2016 Baxter Heavy Industries. All rights reserved.
//

import UIKit

struct Alert {
  
  let alertController: UIAlertController
  let presentingController: UIViewController
  
  init(controller: UIViewController, message: String) {
    
    alertController = UIAlertController(title: "I'm very sorry but ...", message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: "Forgive me", style: .Default, handler: nil)
    alertController.addAction(action)
    
    presentingController = controller
  }
  
  func present() {
    dispatch_async(dispatch_get_main_queue()) {
      self.presentingController.presentViewController(self.alertController, animated: true, completion: nil)
    }
  }
}

