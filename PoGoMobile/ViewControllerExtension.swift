//
//  ViewControllerExtension.swift
//  PoGoMobile
//
//  Created by Tom Albrecht on 10.08.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import UIKit
import CoreLocation
import PGoApi
import MapKit

extension ViewController: PGoAuthDelegate, PGoApiDelegate {
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")
        let request = PGoApiRequest(auth: auth)
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.simulateAppStart()
        request.makeRequest(.Login, delegate: self)
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        if response.subresponses.count == 0 {
            return
        }
        print("Got Api response \(intent), sub responses:\n\n\(response.subresponses)")
        
        
        if (intent == .Login) {
            auth.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(auth.endpoint)")
            getPlayer(0)
        } else if (intent == .GetMapObjects) {
            handleMapObjects(response.subresponses[0] as! Pogoprotos.Networking.Responses.GetMapObjectsResponse)
        } else if intent == .GetPlayer && response.subresponses.count > 0 {
            handlePlayerData(response.subresponses[0] as! Pogoprotos.Networking.Responses.GetPlayerResponse)
        } else if intent == .EncounterPokemon {
            
            if let r = response.subresponses[0] as? Pogoprotos.Networking.Responses.EncounterResponse {
                usernameLbl?.text = "[Encountered \(r.wildPokemon.pokemonData.pokemonId.toString().capitalizedString)] [CP: \(r.wildPokemon.pokemonData.cp)] IV[\(r.wildPokemon.pokemonData.individualAttack)|\(r.wildPokemon.pokemonData.individualDefense)|\(r.wildPokemon.pokemonData.individualStamina)]"
                lastEncounteredPokemon = r.wildPokemon
            }
            
        } else if intent == .GetInventory {
            handleInventory(response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse)
        } else if intent == .CatchPokemon {
            handleCatch(response.subresponses[0] as! Pogoprotos.Networking.Responses.CatchPokemonResponse)
        } else if intent == .PlayerUpdate {
            print("Updated player data");
            if let r = response.subresponses[0] as? Pogoprotos.Networking.Responses.PlayerUpdateResponse {
                print(r)
            }
        } else if intent == .FortSearch {
            let r = response.subresponses[0] as? Pogoprotos.Networking.Responses.FortSearchResponse
            print(r)
            if r!.result == .InCooldownPeriod {
                usernameLbl?.text = "Fort still cooling down"
            } else if r!.result == .Success {
                var str: String = ""
                for it in r!.itemsAwarded {
                    var istr = String(it.itemId)
                    istr = istr.substringFromIndex(istr.rangeOfString(".Item")!.endIndex)
                    str += String(it.itemCount)+"x "+istr+", "
                    
                    
                    
                }
                usernameLbl?.text = "@FORT XP: \(r!.experienceAwarded)\n\(str)"
            }
            
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
}



extension ViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let lbl = UILabel()
        lbl.text = annotation.subtitle!
        print("XLX: \(annotation.subtitle!)")
        lbl.font = UIFont.systemFontOfSize(13)
        
        let v = MKAnnotationView()
        v.leftCalloutAccessoryView = UIButton(type: .InfoDark)
        v.rightCalloutAccessoryView = UIButton(type: .ContactAdd)
        v.image = UIImage(named: "smile")
        v.canShowCallout = true
        v.detailCalloutAccessoryView = lbl
        
        print("called viewForAnnotation")
        
        return v
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        var delay = 0.00
        
        for aV in views {
            let endFrame = aV.frame;
            
            aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 430.0, aV.frame.size.width, aV.frame.size.height);
            delay = delay + 0.01;
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDelay(delay)
            UIView.setAnimationDuration(0.45)
            UIView.setAnimationCurve(.EaseInOut)
            aV.frame = endFrame
            UIView.commitAnimations()
        }
    }
}
