//
//  ViewViewController.swift
//  ToDoList
//
//  Created by Trường Thành on 22/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class EditViewController: UIViewController {
    
    public var item: Item?
    
    public var deletionHandler: (() -> Void)?
    public var editHandler: (() -> Void)?
    
    @IBOutlet var itemTitle: UITextField!
    @IBOutlet var itemDetails: UITextView!
    @IBOutlet var targetedDateLabel: UIButton!
    @IBOutlet var finishedDateLabel: UITextField!
    @IBOutlet var finishedIcon: UIImageView!
    @IBOutlet var categorySegments: UISegmentedControl!
    
    private let realm = try! Realm()
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
    }
    
    func refresh() {
        itemTitle.text = item?.title
        itemDetails.text = item?.details
        targetedDateLabel.setTitle(Self.dateFormatter.string(from: item!.targetedDate), for: .normal)
        targetedDateLabel.contentHorizontalAlignment = .left
        
        // Enable user to change targeted date if the task has not been done
        if (item?.hasDone == true) {
            targetedDateLabel.isEnabled = false
        }
        
        // Get the current category
        switch (item?.category.rawValue) {
        case Item.Category.Work.rawValue:
            categorySegments.selectedSegmentIndex = 0
            break
        case Item.Category.Shopping.rawValue:
            categorySegments.selectedSegmentIndex = 1
            break
        case Item.Category.Learning.rawValue:
            categorySegments.selectedSegmentIndex = 2
            break
        default:
            break
        }
        
        if (item?.hasDone == true) {
            finishedDateLabel.isHidden = false
            finishedDateLabel.text = Self.dateFormatter.string(from: item!.finishedDate)
            finishedIcon.isHidden = false
            if (item?.isOverdue() == true) {
                finishedIcon.image = #imageLiteral(resourceName: "tick red")
            } else {
                finishedIcon.image = #imageLiteral(resourceName: "tick image")
            }
        } else {
            finishedDateLabel.isHidden = true
            finishedIcon.isHidden = true
        }
    }
    
    @IBAction func didTapDelete() {
        guard let myItem = self.item else {
            return
        }
        
        realm.beginWrite()
        realm.delete(myItem)
        try! realm.commitWrite()
        
        deletionHandler?()
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifierString = segue.identifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        switch identifierString {
        case "editDateSegue":
            guard
                let editDateViewController = segue.destination as? EditDateViewController
                else {
                    return
            }
            editDateViewController.item = self.item
            editDateViewController.realm = self.realm
            let backItem = UIBarButtonItem()
            editDateViewController.navigationItem.backBarButtonItem = backItem
            editDateViewController.completionHandler = { [weak self] in
                self?.refresh()
            }
            editDateViewController.navigationItem.largeTitleDisplayMode = .never
            break
        default:
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !(self.item?.isInvalidated ?? true) && self.isMovingFromParent {
            if let title = itemTitle.text, !title.isEmpty, let details = itemDetails.text {
                realm.beginWrite()
                
                self.item?.title = title
                self.item?.details = details
                let category = (categorySegments.selectedSegmentIndex == -1) ? "All" : categorySegments.titleForSegment(at: categorySegments.selectedSegmentIndex)
                self.item?.category = Item.Category(rawValue: category!)!
                
                try! realm.commitWrite()
                
                editHandler?()
                navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
