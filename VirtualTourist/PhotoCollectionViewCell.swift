//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/30/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Cancel photo download if cell is reused
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
