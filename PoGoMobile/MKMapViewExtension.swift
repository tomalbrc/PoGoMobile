//
//  MKMapViewExtension.swift
//  PoGoMobile
//
//  Created by Tom Albrecht on 11.08.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String?, type: MapAnnotationType, userData: AnyObject?) {
        let annotation = MapAnnotation(coordinate: coordinate, type: type)
        annotation.title = title
        annotation.userData = userData
        self.addAnnotation(annotation)
    }
}
