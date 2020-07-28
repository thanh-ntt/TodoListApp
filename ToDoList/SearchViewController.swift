//
//  ViewController.swift
//  ToDoList
//
//  Created by Trường Thành on 22/7/20.
//  Copyright © 2020 Trường Thành. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    private var items = [Item]()
    private var filteredItems: [Item] = []
    
    private let realm = try! Realm(configuration: Realm.Configuration(deleteRealmIfMigrationNeeded: true))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        searchController.searchBar.scopeButtonTitles = Item.Category.allCases.map { $0.rawValue }
        searchController.searchBar.delegate = self
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show most recent tasks first
        items = Array(realm.objects(Item.self)).sorted {
            $0.targetedDate > $1.targetedDate
        }
        filteredItems = items
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func refresh() {
        items = realm.objects(Item.self).map({ $0 })
        tableView.reloadData()
    }
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!isSearchBarEmpty || searchBarScopeIsFiltering)
    }
    
    func filterContentForSearchText(_ searchText: String,
                                    category: Item.Category? = nil) {
        filteredItems = items.filter { (item: Item) -> Bool in
            let doesCategoryMatch = category == .All || item.category == category
            
            if isSearchBarEmpty {
                return doesCategoryMatch
            } else {
                return doesCategoryMatch && (item.title.lowercased().contains(searchText.lowercased()) || item.details.lowercased().contains(searchText.lowercased()))
            }
        }
        
        tableView.reloadData()
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
            editViewController.item = items[indexPath.row]
            editViewController.deletionHandler = { [weak self] in
                self?.refresh()
            }
            editViewController.editHandler = { [weak self] in
                self?.refresh()
            }
            editViewController.navigationItem.largeTitleDisplayMode = .never
        default:
            return
        }
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredItems.count
        } else {
            return items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item: Item
        if isFiltering {
            item = filteredItems[indexPath.row]
        } else {
            item = items[indexPath.row]
        }
        cell.textLabel?.text = item.title
        if (!isFiltering) {  // only show category when not filtering
            cell.detailTextLabel?.text = (item.category.rawValue == "All") ? "" : item.category.rawValue
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        // Display icon based on the status
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
}

extension SearchViewController: UITableViewDelegate {}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let category = Item.Category(rawValue:
            searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex])
        filterContentForSearchText(searchBar.text!, category: category)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let category = Item.Category(rawValue:
            searchBar.scopeButtonTitles![selectedScope])
        filterContentForSearchText(searchBar.text!, category: category)
    }
}
