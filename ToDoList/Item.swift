//
//  Item.swift
//  ToDoList
//
//  Created by Trường Thành on 23/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class Item: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var details: String = ""
    @objc dynamic var targetedDate: Date = Date()
    @objc dynamic var finishedDate: Date = Date().advanced(by: pow(10, 10))  // need a dummy date for RealmSwift
    @objc dynamic var hasDone: Bool = false
    @objc dynamic var isDeleted: Bool = false
    
    // Need a workaround to store enum in RealmSwift
    @objc dynamic var privateCategory: String = Category.All.rawValue
    var category: Category {
        get { return Category(rawValue: privateCategory)! }
        set { privateCategory = newValue.rawValue }
    }

    enum Category: String {
        case All
        case Work
        case Shopping
        case Learning
    }
    
    func finishTask() {
        finishedDate = Date()
        hasDone = true
    }
    
    func undoneTask() {
        finishedDate = Date().advanced(by: pow(10, 10))
        hasDone = false
    }
    
    func isOverdue() -> Bool {
        if (hasDone) {
            return finishedDate > targetedDate
        } else {
            return Date() > targetedDate
        }
    }
    
    func isNotDoneAndOverdue() -> Bool {
        return !hasDone && Date() > targetedDate
    }
    
    func delete() {
        isDeleted = true
    }
}

extension Item.Category: CaseIterable { }
