//
//  EditDateViewController.swift
//  ToDoList
//
//  Created by Trường Thành on 28/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import RealmSwift
import UIKit

class EditDateViewController: UIViewController {
    
    public var item: Item?
    public var realm: Realm?
    public var completionHandler: (() -> Void)?
    
    @IBOutlet var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.setDate(item!.targetedDate, animated: true)
        datePicker.minimumDate = Date()
    }
    
    @IBAction func didTapSaveButton() {
        realm!.beginWrite()
        item?.targetedDate = datePicker.date
        try! realm!.commitWrite()
        
        completionHandler!()
        
        self.navigationController?.popViewController(animated: true)
    }
}
