//
//  Alert.swift
//  OnTheMap
//
//  Created by Dolemite on 1/2/16.
//  Copyright © 2016 Baxter Heavy Industries. All rights reserved.
//

import UIKit

//struct Alert {
//  
//  let alertController: UIAlertController
////  let presentingController: UIViewController
//  
//   init(message: String) {
//      
//      alertController = UIAlertController(title: "I'm very sorry but ...", message: message, preferredStyle: .Alert)
//      let action = UIAlertAction(title: "Forgive me", style: .Default, handler: nil)
//      alertController.addAction(action)
//   }
//  
////  func present() {
////    dispatch_async(dispatch_get_main_queue()) {
////      self.presentingController.presentViewController(self.alertController, animated: true, completion: nil)
////    }
////  }
//}

extension UIAlertController {
   
   class func create(message: String, actionHandler: ((UIAlertAction) -> Void)?) -> UIAlertController  {
      let alertController = UIAlertController(title: "I'm very sorry but ...", message: message, preferredStyle: .Alert)
      alertController.addAction(UIAlertAction(title: "Forgive me", style: .Default, handler: actionHandler))
      return alertController
   }
   
   func present() {
      if let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController {
         presentFromController(rootVC, animated: true) //, completion: nil)
      }
   }
   
// http://stackoverflow.com/questions/25724527/swift-test-class-type-in-switch-statement
   private func presentFromController(controller: UIViewController, animated: Bool) {//, completion: (() -> Void)?) {
      
      switch controller {
         
      case let navVC as UINavigationController:
         if let visibleVC = navVC.visibleViewController {
            presentFromController(visibleVC, animated: animated)
         }
//               if visibleVC is PhotosViewController {
//                  let handler: (UIAlertAction) -> Void = { _ in
//                     navVC.popViewControllerAnimated(true)
//                  }
//                  let action = UIAlertAction(title: "Forgive me", style: .Default, handler: handler)
//                  self.addAction(action)
//               }
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
//   private func presentFromController(controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
//      
//      if  let navVC = controller as? UINavigationController,
//         let visibleVC = navVC.visibleViewController {
//            presentFromController(visibleVC, animated: animated, completion: completion)
//      } else
//         if  let tabVC = controller as? UITabBarController,
//            let selectedVC = tabVC.selectedViewController {
//               presentFromController(selectedVC, animated: animated, completion: completion)
//         } else {
//            controller.presentViewController(self, animated: animated, completion: completion)
//      }
//   }