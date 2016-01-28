//
//  Photo.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/25/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
    @NSManaged var pin: Pin
    @NSManaged var filePath: String
}
