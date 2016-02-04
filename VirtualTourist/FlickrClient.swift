//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Dolemite on 1/29/16.
//  Copyright © 2016 Baxter Heavy Manufacturing Concern. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let sharedInstance = FlickrClient()
    
    let baseURL = "https://api.flickr.com/services/rest/"
    
    var parameters = [
        "method=flickr.photos.getRecent",
        "api_key=3708e5241ec502d213e35d644fa4a6d8",
        "format=json",
        "nojsoncallback=1",
        "accuracy=13"
    ]
    
//    var requestURL: NSURL {
//        
//        // Move to computer prop?
//        
//
//        print(urlString)
//        
//        return NSURL(string: urlString)!
//    }
    
    let urlSession = NSURLSession.sharedSession()
    
    func fetchPhotoPaths(pin: Pin) {
        
        parameters.append("lat=\(pin.latitude)")
        parameters.append("lon=\(pin.longitude)")
        
        let urlString = baseURL + "?" + parameters.joinWithSeparator("&")
        
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        makeFlickrRequest(request) { (json: NSDictionary?, errorString: String?) in
            guard errorString == nil else {
                print(errorString)
                return
            }
            
//            print(json)
            downloadPhotos(json!)
        }
    }
    
    func downloadPhotos(json: NSDictionary?)
    
    func makeFlickrRequest(request: NSURLRequest, handler: (json: NSDictionary?, errorString: String?) -> Void) {
        
        let task = urlSession.dataTaskWithRequest(request) { data, response, error in
            
            guard error == nil else {
                handler(json: nil, errorString: error!.localizedDescription)
                return
            }
            // ANALYZE RESPONSE?
            
            var json: NSDictionary
            
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
                handler(json: json, errorString: nil)
            } catch let error as NSError {
                handler(json: nil, errorString: error.localizedDescription)
            }
        }
        
        task.resume()
    }
}