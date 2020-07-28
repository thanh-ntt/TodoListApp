//
//  EntryViewController.swift
//  ToDoList
//
//  Created by Trường Thành on 22/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import RealmSwift
import UIKit
import UserNotifications

class AddViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet var itemTitle: UITextField!
    @IBOutlet var itemDetails: UITextView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var categorySegments: UISegmentedControl!
    
    private let realm = try! Realm()
    private var item: Item?
    public var completionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.categoryIdentifier == "REMINDER_NOTIFICATION" {
            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                scheduleNotification(atDate: Calendar.current.date(byAdding: .minute, value: 15, to: Date()))
                break
            case "DONE_ACTION":
                self.realm.beginWrite()
                self.item!.finishTask()
                try! self.realm.commitWrite()
                break
            default:
                break
            }
        }
        completionHandler()
    }
    
    func refresh() {
        itemTitle.becomeFirstResponder()
        itemTitle.text = ""
        itemDetails.text = ""
        let currentTime: Date = Date()
        datePicker.setDate(Calendar.current.date(byAdding: .minute, value: 15, to: currentTime)!, animated: true)
        datePicker.minimumDate = currentTime
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == itemTitle) {
            itemTitle.resignFirstResponder()
            itemDetails.becomeFirstResponder()
        } else if (textField == itemDetails) {
            itemDetails.resignFirstResponder()
        }
        return true
    }
    
    func scheduleNotification(minutesBefore: Int? = nil, atDate: Date? = nil) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        
        // Ask user permission to show notification
        notificationCenter.requestAuthorization(options: [.alert, .badge]) { success, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        let categoryIdentifier = "REMINDER_NOTIFICATION"
        
        let content = UNMutableNotificationContent()
        content.title = self.itemTitle.text!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        content.body = "Today at " + dateFormatter.string(from: datePicker.date)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        var dateComponents: DateComponents
        if (minutesBefore != nil) {
            dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Calendar.current.date(byAdding: .minute, value: -minutesBefore!, to: datePicker.date)!)
        } else {
            dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: atDate!)
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "Local Notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze for 15 mins", options: [])
        let markDoneAction = UNNotificationAction(identifier: "DONE_ACTION", title: "Mark as done", options: [.destructive])
        let reminderCategory = UNNotificationCategory(identifier: categoryIdentifier, actions: [snoozeAction, markDoneAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([reminderCategory])
    }
    
    @IBAction func didTapSaveButton() {
        if let title = itemTitle.text, !title.isEmpty, let details = itemDetails.text, let category = (categorySegments.selectedSegmentIndex == -1) ? "All" : categorySegments.titleForSegment(at: categorySegments.selectedSegmentIndex) {
            let newItem = Item()
            newItem.category = Item.Category(rawValue: category)!
            newItem.title = title
            newItem.details = details
            newItem.targetedDate = datePicker.date
            try! realm.write {
                realm.add(newItem)
            }
            self.tabBarController?.selectedIndex = 0
            scheduleNotification(minutesBefore: 60)
            self.item = newItem
            refresh()
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
