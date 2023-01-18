//
//  PlaceEntityStack.swift
//  Map App
//
//  Created by Константин Малков on 04.12.2022.
//

import UIKit
import CoreData
import SPAlert

public class PlaceEntityStack {
    
    static let instance = PlaceEntityStack()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var vaultData = [PlaceEntity]()
    
    
    
    func loadData(){
        do {
            vaultData = try context.fetch(PlaceEntity.fetchRequest())
            print("Load complete")
            
        } catch {
            print("Error loading data")
        }
    }
    
    func saveData(lat: Double,lon: Double, date: String?){
        let place = PlaceEntity(context: context)
        place.date = date
        place.latitude = lat
        place.longitude = lon
        do {
            try context.save()
            
            print("Save successfully \(String(describing: date))")
            //если сохранилось успешно - ставить метку из прозрачной в цветную
        } catch {
            print("error saving data")
            
            
        }
    }
    
    func deleteData(data: PlaceEntity){
        context.delete(data)
        do {
            try context.save()
            print("Delete successfully")
        } catch {
            print("error deleting")
        }
    }

}
