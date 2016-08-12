//
//  InventoryTableViewController.swift
//  PoGoMobile
//
//  Created by Tom Albrecht on 12.08.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import UIKit
import PGoApi
import CoreLocation

class InventoryTableViewController: UITableViewController {
    var auth: PtcOAuth?
    var items = Array<Pogoprotos.Inventory.InventoryItem>()
    var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getInventory(0)
        self.navigationItem.title = "Loading..."
        
        let seg = UISegmentedControl(items: ["Items", "Pokemon", "Eggs"])
        let btn = UIBarButtonItem(customView: seg)
        self.toolbarItems = [UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil), btn, UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)]
        
        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(getInventory))
        self.navigationItem.rightBarButtonItem = refreshBtn
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        if items[indexPath.row].inventoryItemData.hasPokemonData {
            let data = items[indexPath.row].inventoryItemData.pokemonData
            var name = "Egg"
            if !data.isEgg {
                name = data.pokemonId.toString().capitalizedString
            }
            cell.textLabel?.text = "\(name)\n\(data.cp) CP\n[S.A.D.]: \(data.individualStamina)/\(data.individualAttack)/\(data.individualDefense)"
        } else if items[indexPath.row].inventoryItemData.hasItem {
            let data = items[indexPath.row].inventoryItemData.item
            
            cell.textLabel?.text = "\(data.count)x \(data.itemId.toString().capitalizedString)"
        } else {
            // Something else...
            print("Other data: \(items[indexPath.row].inventoryItemData)")
            cell.textLabel?.text = "\(items[indexPath.row].inventoryItemData)".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFontOfSize(10)
        cell.textLabel?.minimumScaleFactor = 0.1
        
        return cell
    }
    
    func getInventory(sender: AnyObject) {
        let request = PGoApiRequest(auth: auth)
        request.setLocation((location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, altitude: (location?.altitude)!)
        request.getInventory()
        request.makeRequest(.GetInventory, delegate: self)
    }
}


extension InventoryTableViewController: PGoApiDelegate {
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        if intent == .GetInventory {
            if let subRe = response.subresponses.first as? Pogoprotos.Networking.Responses.GetInventoryResponse {
                handleInventory(subRe)
            }
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        if statusCode == 102 {
            // Session stale? or was  it 103?
        }
    }
    
    
    
    func handleInventory(data: Pogoprotos.Networking.Responses.GetInventoryResponse) {
        items = data.inventoryDelta.inventoryItems
        self.tableView.reloadData() // hard reload
        
        self.navigationItem.title = "\(items.count) items"
        /* watch out, OLD code
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
        
        //usernameLbl?.text = "Inventory:\n\(pokeballs)x Pokeballs | \(superballs)x Superballs | \(ultraballs)x Ultraballs\n\(potions)x Potions | \(superpotions)x SuperPotions | \(hyperpotions)x HyperPotions | \(maxpotions)x MaxPotions\n\(incenseOrdinary)x Normal Incense | \(luckyeggs)x Lucky Eggs | \(razzberries)x Razzberries\n\nPkmns: \(pkmns)"
        */
    }
}
