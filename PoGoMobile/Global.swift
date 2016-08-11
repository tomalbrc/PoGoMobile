//
//  Global.swift
//  PoGoMobile
//
//  Created by Tom Albrecht on 10.08.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import Foundation
import CoreLocation
import PGoApi

// Some stuff that doesnt really belong anywhere and I want a clean ViewController.swift

func degToRad(deg : Double) -> Double {
    return deg / 180 * M_PI
}

func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let distRadians = distanceMeters / (6372797.6) // earth radius in meters
    
    let lat1 = origin.latitude * M_PI / 180
    let lon1 = origin.longitude * M_PI / 180
    
    let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
    let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
    
    return CLLocationCoordinate2D(latitude: lat2 * 180 / M_PI, longitude: lon2 * 180 / M_PI)
}





class ClientInformation {
    var playerData: Pogoprotos.Data.PlayerData?
    var playerStats: Pogoprotos.Data.Player.PlayerStats?
    var inventoryItems: Array<Pogoprotos.Inventory.InventoryItem>?
}

var clientInformation = ClientInformation()

