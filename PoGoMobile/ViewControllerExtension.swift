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
            auth?.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(auth?.endpoint)")
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
            
        } else if intent == .CatchPokemon {
            handleCatch(response.subresponses[0] as! Pogoprotos.Networking.Responses.CatchPokemonResponse)
        } else if intent == .PlayerUpdate {
            print("Updated player position");
        } else if intent == .FortSearch {
            let r = response.subresponses.first as? Pogoprotos.Networking.Responses.FortSearchResponse
            if r!.result == .InCooldownPeriod {
                usernameLbl?.text = "Fort still cooling down"
            } else if r!.result == .Success {
                var str: String = ""
                for item in r!.itemsAwarded {
                    let itemIDStr = item.itemId.toString()
                    str += "\(item.itemCount)x \(itemIDStr), "
                }
                usernameLbl?.text = "@Spun Fort, EXP: \(r!.experienceAwarded)\n\(str)"
            }
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        usernameLbl?.text = "API Error: \(statusCode)"
        print(usernameLbl?.text)
    }
}



extension ViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MapAnnotation {
            let lbl = UILabel()
            lbl.font = UIFont.systemFontOfSize(9)
            
            if let pokemon = annotation.userData as? Pogoprotos.Map.Pokemon.MapPokemon {
                lbl.text = pokemon.pokemonId.toString().capitalizedString
            } else if let fort = annotation.userData as? Pogoprotos.Map.Fort.FortData {
                lbl.text = fort.id
            }
            
            
            let annotationView = MKAnnotationView()
            if annotation.type == .Fort {
                let btn = TAButton()
                btn.frame = CGRectMake(0, 0, 50, 44)
                btn.setImage(UIImage(named: "runner"), forState: .Normal)
                btn.backgroundColor = UIColor(red: 25/1.0, green: 150/1.0, blue: 235/1.0, alpha: 1.0)
                btn.addTarget(self, action: #selector(walkToFort), forControlEvents: .TouchUpInside)
                btn.userData = annotation
                annotationView.leftCalloutAccessoryView = btn
            } else if annotation.type == .Pokemon {
                
            } else {
                let btn = UIButton(type: .DetailDisclosure)
                annotationView.rightCalloutAccessoryView = btn
            }
            annotationView.image = UIImage(named: "smile")
            annotationView.canShowCallout = true
            annotationView.detailCalloutAccessoryView = lbl
            
            return annotationView
        }
        return nil
    }
    
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        var delay = 0.00
        
        for aV in views {
            let endFrame = aV.frame;
            
            aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 430.0, aV.frame.size.width, aV.frame.size.height);
            delay = delay + 0.01;
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDelay(delay)
            UIView.setAnimationDuration(0.42)
            UIView.setAnimationCurve(.EaseInOut)
            aV.frame = endFrame
            UIView.commitAnimations()
        }
    }
}
