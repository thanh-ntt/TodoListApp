//
//  TodayViewController.swift
//  ToDoList
//
//  Created by Trường Thành on 24/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class TodayViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var runningFigure: UIImageView!
    @IBOutlet var finishLineFigure: UIImageView!
    @IBOutlet var welcomeFigure: UIImageView!
    
    private var sectionToItems = [[Item]]()
    
    // Simplify migration logic: clear all data if migration needed
    private let realm = try! Realm(configuration: Realm.Configuration(deleteRealmIfMigrationNeeded: true))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    // Logic to organize/display the view
    func refresh() {
        let today: Date = Date()
        
        // Show items due today / overdue and not been done (maybe from previous day)
        let importantItems = Array(realm.objects(Item.self)).filter { (item: Item) -> Bool in
            !item.isDeleted && (Calendar.current.isDate(item.targetedDate, inSameDayAs:today) || item.isNotDoneAndOverdue())
        }
        sectionToItems = [[Item](), [Item]()]
        for i in importantItems {
            if (!i.hasDone) {
                sectionToItems[0].append(i)
            } else {
                sectionToItems[1].append(i)
            }
        }
        
        // Show the nearest upcoming todo tasks first
        sectionToItems[0].sort {
            $0.targetedDate < $1.targetedDate
        }
        // Show the newest done tasks first
        sectionToItems[1].sort {
            $0.finishedDate > $1.finishedDate
        }
        tableView.reloadData()
        
        // Show a motivational quote
        self.navigationItem.title = getQuote()
        
        // Show interesting images / animation
        updateTopImages()
    }
    
    func getQuote() -> String {
        var quotes = [String]()
        // Show motivational quote
        if (sectionToItems[0].count == 0) {
            if (sectionToItems[1].count == 0) {
                quotes.append("Try adding a task")
            } else {
                quotes.append("Let's Netflix and chill")
                quotes.append("Done? Let's hangout with friends!")
            }
        } else {
            let doneTasksRatio = getDoneTasksRatio()
            if (doneTasksRatio < 0.2) {
                quotes.append("Only \(sectionToItems[0].count) tasks? What a beautiful day!")
                quotes.append("Don't know where to start? Try \"\(sectionToItems[0].randomElement()?.title ?? "")\"")
            } else if (doneTasksRatio < 0.66) {
                quotes.append("You can do it!")
                quotes.append("Fighting!")
                quotes.append("Procrastination is the thief of time")
                quotes.append("Little things make big days")
                quotes.append("Keep it up")
            } else {
                quotes.append("Almost done")
                quotes.append("Only \(sectionToItems[0].count) tasks to go")
            }
        }
        if (!quotes.isEmpty) {
            return quotes.randomElement()!
        } else {
            return "To Do"
        }
    }
    
    func updateTopImages() {
        if (sectionToItems[0].count == 0) {
            finishLineFigure.isHidden = true
            runningFigure.isHidden = true
            welcomeFigure.isHidden = false
            if (sectionToItems[1].count == 0) { // no tasks at all
                welcomeFigure.image = #imageLiteral(resourceName: "hi there")
            } else {  // Finished all tasks
                welcomeFigure.image = #imageLiteral(resourceName: "mission completed")
            }
        } else {  // have todo tasks
            welcomeFigure.isHidden = true
            runningFigure.isHidden = false
            finishLineFigure.isHidden = false
            runningFigure.image = #imageLiteral(resourceName: "stickman running")
            let destinationX:CGFloat = CGFloat(getDoneTasksRatio() * 300 + 46)
            UIView.animate(withDuration: 0.5, delay: 0.3, options: UIView.AnimationOptions.transitionFlipFromLeft, animations: {
                self.runningFigure.center.x = destinationX
            }, completion: nil)
        }
    }
    
    func getDoneTasksRatio() -> Double {
        if (sectionToItems[1].count + sectionToItems[0].count == 0) {
            return 0;
        } else {
            return Double(sectionToItems[1].count) / Double(sectionToItems[1].count + sectionToItems[0].count)
        }
    }
}

extension TodayViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionToItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item: Item = sectionToItems[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.details
//        cell.setEditing(true, animated: true)

        let imageView: UIImageView = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
        if (item.isNotDoneAndOverdue()) {
            imageView.image = #imageLiteral(resourceName: "exclamation mark")
        } else if (item.isOverdue()) {  // done and overdue
            imageView.image = #imageLiteral(resourceName: "tick red")
        } else if (item.hasDone) {  // done and not overdue
            imageView.image = #imageLiteral(resourceName: "tick image")
        }
        imageView.contentMode = .scaleAspectFit
        cell.accessoryView = imageView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            let markDone = UIContextualAction(style: .normal, title: "Done") { (action, view, completion) in
                let item: Item = self.sectionToItems[indexPath.section][indexPath.row]
                self.realm.beginWrite()
                item.finishTask()
                try! self.realm.commitWrite()
                self.refresh()
                completion(true)
            }
            markDone.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            return UISwipeActionsConfiguration(actions: [markDone])
        } else if indexPath.section == 1 {
            let markUndone = UIContextualAction(style: .normal, title: "Un-done") { (action, view, completion) in
                let item: Item = self.sectionToItems[indexPath.section][indexPath.row]
                self.realm.beginWrite()
                item.undoneTask()
                try! self.realm.commitWrite()
                self.refresh()
                completion(true)
            }
            markUndone.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            return UISwipeActionsConfiguration(actions: [markUndone])
        }
        return UISwipeActionsConfiguration(actions: [])
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Todo"
        } else {
            return "Done"
        }
    }
    
    // Prepare data to move to other view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifierString = segue.identifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        switch identifierString {
//        case "addItemSegue":
//            let addViewController = segue.destination as! AddViewController
//            addViewController.completionHandler = { [weak self] in
//                self?.refresh()
//            }
//            addViewController.title = "New Item"
//            addViewController.navigationItem.largeTitleDisplayMode = .never
        case "showItemSegue":
            guard
                let indexPath = tableView.indexPathForSelectedRow,
                let editViewController = segue.destination as? EditViewController
                else {
                    return
            }
            editViewController.item = sectionToItems[indexPath.section][indexPath.row]
            editViewController.deletionHandler = { [weak self] in
                self?.refresh()
            }
            editViewController.editHandler = { [weak self] in
                self?.refresh()
            }
            editViewController.navigationItem.largeTitleDisplayMode = .never
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
        default:
            return
        }
    }
}

extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        let lbl = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width - 15, height: 40))
        switch section {
        case 0:
            view.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            lbl.text = "Todo"
        case 1:
            view.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            lbl.text = "Done"
        default:
            view.backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
            lbl.text = "Overdue"
        }
        view.addSubview(lbl)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
