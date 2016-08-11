//
//  MapAnnotation.swift
//  PoGoMobile
//
//  Created by Tom Albrecht on 11.08.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import Foundation
import MapKit
import PGoApi


enum MapAnnotationType {
    case Pokemon 
    case Fort
    case Player
}

class MapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var type: MapAnnotationType

    var customTitle: String?
    
    var userData: AnyObject?
    
    init(coordinate: CLLocationCoordinate2D, type: MapAnnotationType) {
        self.coordinate = coordinate
        self.type = type
    }
}