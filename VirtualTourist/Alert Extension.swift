//
//  Alert.swift
//  OnTheMap
//
//  Created by Dolemite on 1/2/16.
//  Copyright © 2016 Baxter Heavy Industries. All rights reserved.
//

import UIKit

// Reusable alert with custom handler that can be called in one VC but show up in another
// Inspired by stackoverflow post I lost track of
extension UIAlertController {
   
   class func create(message: String, actionHandler: ((UIAlertAction) -> Void)?) -> UIAlertController  {
      let alertController = UIAlertController(title: "I'm sorry but ...", message: message, preferredStyle: .Alert)
      alertController.addAction(UIAlertAction(title: "Forgive me", style: .Default, handler: actionHandler))
      return alertController
   }
   
   func present() {
      if let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController {
         presentFromController(rootVC, animated: true)
      }
   }
   
   private func presentFromController(controller: UIViewController, animated: Bool) {
      
      switch controller {
         
      case let navVC as UINavigationController:
         if let visibleVC = navVC.visibleViewController {
            presentFromController(visibleVC, animated: animated)
         }
      case let tabVC as UITabBarController:
         if let selectedVC = tabVC.selectedViewController {
            presentFromController(selectedVC, animated: animated) //, completion: nil)
         }
      default:
         dispatch_async(dispatch_get_main_queue()) {
            controller.presentViewController(self, animated: animated, completion: nil)
         }
      }
   }
}