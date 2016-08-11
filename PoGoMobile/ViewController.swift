//
//  ViewController.swift
//  PGoApi
//
//  Created by Luke Sapan on 08/02/2016.
//  Copyright (c) 2016 Luke Sapan. All rights reserved.
//

import UIKit
import CoreLocation
import PGoApi
import MapKit

class ViewController: UIViewController {
    @IBOutlet var usernameLbl: UILabel?
    @IBOutlet var fortLbl: UILabel?
    @IBOutlet var mapView: MKMapView?
    
    var isWalking = false
    
    
    var auth: PtcOAuth!
    
    var location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.331729, longitude: -122.028834), altitude: 1.0391204, horizontalAccuracy: 1.0, verticalAccuracy: 1.0, timestamp: NSDate())
    var foundPokemons = Array<Pogoprotos.Map.Pokemon.MapPokemon>()
    var foundForts = Array<Pogoprotos.Map.Fort.FortData>()
    var lastEncounteredPokemon: Pogoprotos.Map.Pokemon.WildPokemon?
    var lastSelectedFort: Pogoprotos.Map.Fort.FortData?
}

extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = PtcOAuth()
        auth.delegate = self
        auth.login(withUsername: "", withPassword: "")
        
        /// Google auth
        // var a = GPSOAuth()
        // a.login(withUsername: "", withPassword: "")
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Initial position"
        
        addAnnotation(location.coordinate, title: "Initial position", subtitle: nil)
        
        mapView?.region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView?.addAnnotation(annotation)
        
    }
    
    
    func addAnnotation(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        mapView?.addAnnotation(annotation)
    }
    
    
    @IBAction func getPlayer(sender: AnyObject) {
        let request = PGoApiRequest(auth: auth)
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.getPlayer()
        request.makeRequest(.GetPlayer, delegate: self)
    }
    
    
    @IBAction func getMapObjects(sender: AnyObject) {
        let request = PGoApiRequest(auth: auth)
        
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.getMapObjects();
        request.makeRequest(.GetMapObjects, delegate: self)
    }
    
    @IBAction func getInventory(sender: AnyObject) {
        let request = PGoApiRequest(auth: auth)
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.getInventory()
        request.makeRequest(.GetInventory, delegate: self)
    }
    
    
    // Actually walks to the next fort available
    func updateLocation() {
        let request = PGoApiRequest(auth: auth)
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.updatePlayer()
        request.makeRequest(.PlayerUpdate, delegate: self)
    }
    
    @IBAction func tryCatch(sender: AnyObject) {
        if (lastEncounteredPokemon != nil) {
            //let poke = encounteredPokemon!.pokemonData
            //let name = String(poke.pokemonId)
            //let va = name.substringWithRange(name.startIndex.advancedBy(1) ..< name.endIndex)
            
            let request = PGoApiRequest(auth: auth)
            request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
            request.catchPokemon(lastEncounteredPokemon!.encounterId, spawnPointId: lastEncounteredPokemon!.spawnPointId, pokeball: .ItemPokeBall, hitPokemon: true, normalizedReticleSize: 1.950, normalizedHitPosition: 1, spinModifier: 1)
            request.makeRequest(.CatchPokemon, delegate: self)
        } else {
            // No pokemon to catch
        }
    }
    
    
    @IBAction func walkToFort(sender: AnyObject) {
        if (lastSelectedFort == nil && foundForts.count == 0) {
            usernameLbl?.text = "No forts available! Tap \"Get MapObjects\" first"
            return
        } else if foundForts.count > 0 {
            lastSelectedFort = foundForts.first
            foundForts.removeFirst()
        } else {return}
        
        
        usernameLbl?.text = "Walking to \(lastSelectedFort!.id)"
        
        let difLat = lastSelectedFort!.latitude - location.coordinate.latitude
        let difLon = lastSelectedFort!.longitude - location.coordinate.longitude
        //let distance = sqrt(pow(difLat,2)+pow(difLon,2))
        
        let angle = atan2(difLon, difLat)
        
        
        let newLoc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lastSelectedFort!.latitude, longitude: lastSelectedFort!.longitude), altitude: location.altitude, horizontalAccuracy: 1.0, verticalAccuracy: 1.0, timestamp: NSDate())
        let distanceMeters = location.distanceFromLocation(newLoc)
        
        let walkSpeedInMS = 20.0 /* meters/s */
        stepWithStepAmount(walkSpeedInMS, bearing: angle, totalDistance: distanceMeters, walkedDistance: 0)
        fortLbl?.text = "Walking for \(ceil(distanceMeters/20.0)) seconds"
    }
    func spinCurrentFort() {
        let request = PGoApiRequest(auth: auth)
        request.setLocation(lastSelectedFort!.latitude, longitude: lastSelectedFort!.longitude, altitude: location.altitude)
        request.fortSearch(lastSelectedFort!.id, fortLatitude: lastSelectedFort!.latitude, fortLongitude: lastSelectedFort!.longitude)
        request.makeRequest(.FortSearch, delegate: self)
    }
    
    func stepWithStepAmount(stepAmount: Double, bearing: Double, totalDistance: Double, walkedDistance: Double) {
        if walkedDistance+stepAmount >= totalDistance {
            isWalking = false
            if (lastSelectedFort != nil) { self.spinCurrentFort() }
        } else {
            isWalking = true
            
            let lc = locationWithBearing(bearing, distanceMeters: stepAmount, origin: location.coordinate)
            
            let lat = lc.latitude
            let lon = lc.longitude
            location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: 1.0391204, horizontalAccuracy: 1.0, verticalAccuracy: 1.0, timestamp: NSDate())
            self.updateLocation()
            
            // DEBUG
            addAnnotation(location.coordinate, title: "\(location.coordinate.latitude), \(location.coordinate.longitude)", subtitle: "DEBUG | WALKED HERE")
            
            delayClosure(1.0) {
                self.stepWithStepAmount(stepAmount, bearing: bearing, totalDistance: totalDistance, walkedDistance: walkedDistance+stepAmount)
            }
        }
    }
    
    
    
    
    func encounterPokemon(pokeWild: Pogoprotos.Map.Pokemon.MapPokemon) {
        let request = PGoApiRequest(auth: auth)
        request.setLocation(location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude)
        request.encounterPokemon(pokeWild.encounterId, spawnPointId: pokeWild.spawnPointId)
        request.makeRequest(.EncounterPokemon, delegate: self)
    }
    
    func handlePlayerData(data: Pogoprotos.Networking.Responses.GetPlayerResponse) {
        clientInformation.playerData = data.playerData
        
        if let playerData = data.playerData {
            if playerData.hasUsername {
                let c1name = playerData.currencies[0].name.capitalizedString
                let c2name = playerData.currencies[1].name.capitalizedString
                let c1val = String(playerData.currencies[0].amount)
                let c2val = String(playerData.currencies[1].amount)
                
                usernameLbl?.text = "Player data:\n\n\(playerData.username)\nTeam: \(playerData.team.toString().capitalizedString)\n\(c1name): \(c1val)\n\(c2name): \(c2val)"
            }
        }
    }
    
    func handleInventory(data: Pogoprotos.Networking.Responses.GetInventoryResponse) {
        clientInformation.inventoryItems = data.inventoryDelta.inventoryItems
        for item in data.inventoryDelta.inventoryItems {
            if item.inventoryItemData.hasPlayerStats {
                clientInformation.playerStats = item.inventoryItemData.playerStats
            }
        }
        
        var incenseOrdinary = 0
        var potions = 0
        var superpotions = 0
        var hyperpotions = 0
        var maxpotions = 0
        var pokeballs = 0
        var superballs = 0
        var ultraballs = 0
        var razzberries = 0
        var luckyeggs = 0
        var pkmns = 0
        for item in data.inventoryDelta.inventoryItems {
            if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemPokeBall { pokeballs = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemGreatBall { superballs = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemUltraBall { ultraballs = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemPotion { potions = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemSuperPotion { superpotions = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemHyperPotion { hyperpotions = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemMaxPotion { maxpotions = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemLuckyEgg { luckyeggs = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemRazzBerry { razzberries = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasItem && item.inventoryItemData.item.itemId == .ItemIncenseOrdinary { incenseOrdinary = Int(item.inventoryItemData.item.count) }
            else if item.inventoryItemData.hasPokemonData { pkmns += 1 }
        }
        
        usernameLbl?.text = "Inventory:\n\(pokeballs)x Pokeballs | \(superballs)x Superballs | \(ultraballs)x Ultraballs\n\(potions)x Potions | \(superpotions)x SuperPotions | \(hyperpotions)x HyperPotions | \(maxpotions)x MaxPotions\n\(incenseOrdinary)x Normal Incense | \(luckyeggs)x Lucky Eggs | \(razzberries)x Razzberries\n\nPkmns: \(pkmns)"
    }
    
    func handleCatch(data: Pogoprotos.Networking.Responses.CatchPokemonResponse) {
        let r = data
        print("Catch Pokemon Response")
        print(r.status)
        if r.status == .CatchSuccess {
            let sumCandy = r.captureAward.candy.reduce(0, combine: +)
            let sumStardust = r.captureAward.stardust.reduce(0, combine: +)
            let sumXP = r.captureAward.xp.reduce(0, combine: +)
            usernameLbl?.text = "Caught \(lastEncounteredPokemon!.pokemonData.pokemonId)!\nEarned \(sumXP), \(sumCandy) candy, \(sumStardust) stardust)"
        } else if r.status == .CatchEscape {
            usernameLbl?.text = "\(lastEncounteredPokemon!.pokemonData.pokemonId) could escape. Trying again..."
            tryCatch(0)
        } else if r.status == .CatchFlee {
            usernameLbl?.text = "\(lastEncounteredPokemon!.pokemonData.pokemonId) Vanished :("
        }
    }
    
    func handleMapObjects(data: Pogoprotos.Networking.Responses.GetMapObjectsResponse) {
        let r = data
        
        foundForts.removeAll()
        foundPokemons.removeAll()
        
        var i = 0
        for cell in r.mapCells {
            print("Run #\(i)")
            print(cell)
            
            foundPokemons.appendContentsOf(cell.catchablePokemons)
            foundForts.appendContentsOf(cell.forts)
            
            i+=1
        }
        
        for pkmn in foundPokemons {
            addAnnotation(CLLocationCoordinate2D(latitude: pkmn.latitude, longitude: pkmn.longitude), title: pkmn.pokemonId.toString(), subtitle: nil)
        }
        for fort in foundForts {
            addAnnotation(CLLocationCoordinate2D(latitude: fort.latitude, longitude: fort.longitude), title: fort.hasOwnedByTeam ? "Gym" : "PokeStop", subtitle: fort.id)
        }
        
        
        
        usernameLbl?.text = "Found forts: \(foundForts.count)\nFound Pokemon: \(foundPokemons.count)"
    }
}
