//
//  PlaceEntity+CoreDataProperties.swift
//  Map App
//
//  Created by Константин Малков on 04.12.2022.
//
//

import Foundation
import CoreData


extension PlaceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaceEntity> {
        return NSFetchRequest<PlaceEntity>(entityName: "PlaceEntity")
    }

    @NSManaged public var place: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: String?
    @NSManaged public var placemarkAttribute: String?

}

extension PlaceEntity : Identifiable {

}
