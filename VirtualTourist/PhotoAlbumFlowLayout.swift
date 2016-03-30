//
//  PhotoAlbumFlowLayout.swift
//  VirtualTourist
//
//  Created by Dolemite on 3/15/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import UIKit
import Foundation

// Stolen from http://dativestudios.com/blog/2015/01/08/collection_view_layouts_on_wide_phones/
class PhotoAlbumFlowLayout: UICollectionViewFlowLayout {
   
   var numberOfItemsPerRow : Int {
      if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
         return 4
      } else {
         return 8
      }
   }
   
   override func prepareLayout() {
      super.prepareLayout()
      
      if let collectionView = self.collectionView {
         
         var newItemSize = itemSize
         
         // Always use an item count of at least 1
         let itemsPerRow = CGFloat(max(numberOfItemsPerRow, 1))
         
         // Calculate the sum of the spacing between cells
         let totalSpacing = minimumInteritemSpacing * (itemsPerRow - 1.0)
         
         // Calculate how wide items should be
         newItemSize.width = (collectionView.bounds.size.width - totalSpacing) / itemsPerRow
         
         // Use the aspect ratio of the current item size to determine how tall the items should be
         if itemSize.height > 0 {
            let itemAspectRatio = itemSize.width / itemSize.height
            newItemSize.height = newItemSize.width / itemAspectRatio
         }
         
         // Set the new item size
         itemSize = newItemSize
      }
   }
}
