//
//  SearchHistoryStack.swift
//  Map App
//
//  Created by Константин Малков on 17.01.2023.
//

import UIKit
import CoreData
import SPAlert

class SearchHistoryStack {
    static let instance = SearchHistoryStack()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var historyVault = [SearchHistory]()
    
    func loadHistoryData(){
        do {
            historyVault = try context.fetch(SearchHistory.fetchRequest())
        } catch {
            SPAlert.present(message: "Error loading history", haptic: .error)
        }
    }
    
    func saveHistoryDataElement(name: String, lan: Double, lon: Double){
        let vault = SearchHistory(context: context)
        vault.nameCategory = name
        vault.langitude = lan
        vault.longitude = lon
        do {
            try context.save()
        } catch {
            SPAlert.present(message: "Error saving", haptic: .error)
        }
        
    }
    
    func deleteHistoryDataElement(){
        
    }
}
