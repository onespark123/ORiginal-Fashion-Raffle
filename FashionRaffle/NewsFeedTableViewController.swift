//
//  NewsFeedTableViewController.swift
//  FashionRaffle
//
//  Created by Spark Da Capo on 11/15/16.
//  Copyright © 2016 Mac. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SVProgressHUD
import Cache
import Imaginary
import ESPullToRefresh

class NewsFeedTableViewController: UITableViewController, UISearchBarDelegate {
    
    var newsF : [NewsFeed] = []
    // search attributes
    //let searchBar = UISearchBar()
    var label : UILabel?
    
    var currentLoad : UInt = 2
    var singleLoadLimit: UInt = 2
    //var shouldFiltContents = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if FIRAuth.auth()?.currentUser == nil {
            print("User not signed in. Will go to log in page")
            SVProgressHUD.dismiss()
            if FBSDKAccessToken.current() != nil {
                FBSDKLoginManager().logOut()
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
            self.present(loginVC, animated: true, completion: nil)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = loginVC
        }
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        label?.text = self.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search button"), style: .plain, target: self, action: #selector(self.searchTapped))
        self.tableView.es_addPullToRefresh {
            self.refresh()
        }
        self.tableView.es_addInfiniteScrolling {

            self.loadMore()
        }
        
        loadAttributes()

        
    }
    
    //Load Functionality
    
    func loadAttributes() {
        
        SettingsLauncher.showLoading(Status: "Loading...")
        newsF.removeAll()
        // query limited to last int m will return the most recent m items (if generated by autoID)

        ref.child("ReleaseNews").queryOrderedByKey().queryLimited(toLast: self.currentLoad).observe(.childAdded, with: {
            snapshot in
            guard let newsFeed = snapshot.value as? [String:Any] else{
                return
            }

            let newsID = snapshot.key
            let new = NewsFeed.initWithNewsID(newsID: newsID, contents: newsFeed)
            self.newsF.insert(new!, at: 0)
            DispatchQueue.main.async {

                self.tableView.reloadData()
                SettingsLauncher.dismissLoading()
                ref.child("ReleaseNews").removeAllObservers()

            }
        }, withCancel:{
            error in
            print(error.localizedDescription)
        })
    }
    
    func refresh() {
        // query limited to last int m will return the most recent m items (if generated by autoID)
        ref.child("ReleaseNews").queryLimited(toLast: 1).observeSingleEvent(of: .value, with: {
            snapshot in
            guard let checkLatestNews = snapshot.value as? [String:[String:Any]] else {
                print("Fetch latest News failed")
                return
            }
            for (newsID, _) in checkLatestNews {
                let checkID = self.newsF[0].newsID
                if newsID == checkID {
                    // There is no new data, no need to fetch all the news once again
                    print("No new feeds")
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3, execute: {
                        self.tableView.es_stopPullToRefresh()
                    })
                    return
                    
                }
            }
            // Has New data
            print("Will fetch new data")
            self.newsF.removeAll()
            ref.child("ReleaseNews").queryOrderedByKey().queryLimited(toLast: self.currentLoad).observe(.childAdded, with: {
                snapshot in
                guard let newsFeed = snapshot.value as? [String:Any] else{
                    return
                }
                let newsID = snapshot.key
                let new = NewsFeed.initWithNewsID(newsID: newsID, contents: newsFeed)
                self.newsF.insert(new!, at: 0)
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                    self.tableView.es_stopPullToRefresh()
                    ref.child("ReleaseNews").removeAllObservers()
                    
                }
            }, withCancel:{
                error in
                print(error.localizedDescription)
            })
        }, withCancel: {
            error in
            print(error.localizedDescription)
        })
        
    }
    
    func loadMore() {
        //Still more data
        if currentLoad <= UInt(newsF.count) {
            currentLoad = currentLoad + singleLoadLimit
            let checkCount = self.newsF.count
            self.newsF.removeAll()
            ref.child("ReleaseNews").queryOrderedByKey().queryLimited(toLast: self.currentLoad).observe(.childAdded, with: {
                snapshot in
                guard let newsFeed = snapshot.value as? [String:Any] else{
                    return
                }
                
                let newsID = snapshot.key
                let new = NewsFeed.initWithNewsID(newsID: newsID, contents: newsFeed)
                self.newsF.insert(new!, at: 0)
                DispatchQueue.main.async {
                    
                    if self.newsF.count == checkCount {
                        // No more data
                        print("No more data")
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: {
                            self.tableView.es_noticeNoMoreData()
                            ref.child("ReleaseNews").removeAllObservers()
                            return
                        })
                    }
                    if self.newsF.count > checkCount {
                        // Has more data
                        print("Has more data")
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3, execute: {
                            self.tableView.es_stopLoadingMore()
                            self.tableView.reloadData()
                            ref.child("ReleaseNews").removeAllObservers()
                        })
                        

                    }
                }
            }, withCancel:{
                error in
                print(error.localizedDescription)
            })

        }
        else {
            //No more data
            print("No more data to load")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: {
                self.tableView.es_noticeNoMoreData()
            })
            
        }
    }
    
    //The function for search bar
    
    func searchTapped() {
        /*
         searchBar.delegate = self
         searchBar.tintColor = UIColor(red: 55/255, green: 183/255, blue: 255/255, alpha: 1)
         
         searchBar.isHidden = false
         searchBar.showsCancelButton = false
         searchBar.placeholder = "Explore your interest!"
         self.navigationItem.titleView = searchBar
         self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelsearch))
         */
    }
    
    //cancel the search if needed
    
    func cancelsearch() {
        /*
         searchBar.text = ""
         shouldFiltContents = false
         self.tableView.reloadData()
         searchBar.isHidden = true
         self.navigationItem.titleView = label
         self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
         self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search button"), style: .plain, target: self, action: #selector(self.searchTapped))
         */
    }
    
    
    // Function for search bar ends
    
    //Search Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        /*
         self.filterednewsDatas = newsDatas.filter({content -> Bool in
         let title = content.title
         return title.lowercased().contains(searchText.lowercased())
         
         })
         if searchText != "" {
         shouldFiltContents = true
         self.tableView.reloadData()
         }
         else {
         shouldFiltContents = false
         self.tableView.reloadData()
         }
         */
        
    }
    
    
    
    //Search Functions end
    
    //Close Search Bar if needed
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //searchBar.endEditing(true)
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        /*searchBar.endEditing(true)
         shouldFiltContents = true
         self.tableView.reloadData()
         */
    }
    
    
    //Close search bar functions end
    
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        /*
         self.tableView.reloadData()
         refreshControl.endRefreshing()
         */
    }
    
    
    //TableView Delegates
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsDataCell
        
        let newsCell = self.newsF[indexPath.row]
        if let imageUrl = newsCell.headImageUrl{
            cell.Cellimage.setImage(url: imageUrl)
        }
        
        
        cell.timestamp!.text = newsCell.timestamp
        cell.Title!.text = newsCell.title
        cell.Subtitle!.text = newsCell.subtitle
        if let releaseDate = newsCell.releaseDate {
            cell.releaseDateEvent.setTitle(releaseDate, for: .normal)
        }
        else {
            cell.releaseDateEvent.setTitle("TBD", for: .normal)
        }
        return cell

    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let feed = self.newsF
        return feed.count
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        /*
        let newsCell = self.newsF[indexPath.row]
        NewsFeed.selectedNews = newsCell
        let storyboard = UIStoryboard(name: "FirstDemo", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NewsReusableView") as! NewsReusableViewController
        //searchBar.endEditing(true)
        self.navigationController?.pushViewController(viewController, animated: true)
 */
        print("CoolCool")
    }
    
    //TableView Delegates end
    
    
    //Search bar delegates
    
    /*
     func updateSearchResults(for searchController: UISearchController) {
     // updates
     filterContents(searchText: self.searchController.searchBar.text!)
     }
     */
    //Search Bar delegates end
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
