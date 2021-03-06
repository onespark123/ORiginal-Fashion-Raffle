//
//  NewsReusableViewController.swift
//  FashionRaffle
//
//  Created by Spark Da Capo on 11/15/16.
//  Copyright © 2016 Mac. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorageUI
import SVProgressHUD



class NewsReusableViewController: UIViewController {
    
    
    @IBOutlet weak var NewsTitle: UILabel!
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var Details: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "likeicon"), style: .plain, target: self, action: #selector(handlelike))
        let selectedNews = (NewsFeed.selectedNews)!
        self.title = selectedNews.title
        self.NewsTitle.text = selectedNews.title
        self.Details.text = selectedNews.detailInfo
        self.Image.image = selectedNews.titleImage
        
    }
    
    func handlelike() {
        
    }
    /*
    func checklikes() {
        let child = self.passKey
        let userID = FIRAuth.auth()?.currentUser?.uid
        self.ref.child(child!).child("Liked Users").observeSingleEvent(of: .value, with: {
            snapshot in
            if snapshot.hasChild(userID!){
                self.check = true
            }
            else {
                self.check = false
            }
            
        })
    }
 */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}

class RaffleReusableViewController: UIViewController {
    @IBOutlet weak var Label1: UILabel!
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var Details: UILabel!
    @IBOutlet var PaymentView: UIView!
    
    @IBOutlet var SliderTickets: UISlider!
    @IBOutlet var numberLabel: UILabel!
    
    var reference: FIRStorageReference!
    let ref = FIRDatabase.database().reference()
    var passLabel : String!
    var passDetail : String!
    var passKey: String!
    var check = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        self.checklikes()
        let likeBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "likeicon"), style: .plain, target: self, action: #selector(handlelike))
        navigationItem.rightBarButtonItems = [likeBarButton]
        self.Label1.text = passLabel
        self.Details.text = passDetail
        self.Image.sd_setImage(with: reference)
        
        
    }
    
    let dimView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return view
    }()
    @IBAction func BuyButton(_ sender: Any) {
        handlepurchase()
    }
    
    func handlepurchase() {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        let location = "Users"
        ref.child(location).child(userID!).observeSingleEvent(of: .value, with: {
            snapshot in
            let value = snapshot.value as? NSDictionary
            let hastickets = value!["tickets"] as! Int
            self.SliderTickets.minimumValue = 1
            if hastickets < 6 {
                self.SliderTickets.maximumValue = Float(hastickets)
            }
            else{
                self.SliderTickets.maximumValue = 5
            }
        })
        
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(dimView)
            window.addSubview(PaymentView)
            self.dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            self.dimView.frame = window.frame
            self.dimView.alpha = 0
            let height = self.PaymentView.frame.height
            let width = self.PaymentView.frame.width
            let y = window.frame.height - height - 60
            self.PaymentView.layer.cornerRadius = 10
            self.PaymentView.frame = CGRect(x: 37.5, y: window.frame.height, width: width, height: height)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.dimView.alpha = 1
                self.PaymentView.frame = CGRect(x: 37.5, y: y, width: width, height: height)
            }, completion: nil)
        }
    }
    
    
    func handleDismiss() {
        if let window = UIApplication.shared.keyWindow {
            UIView.animate(withDuration: 0.4, animations: {
                self.PaymentView.frame = CGRect(x: 37.5, y: window.frame.height, width: self.PaymentView.frame.width, height: self.PaymentView.frame.height)
                self.dimView.alpha = 0
            }) {(success : Bool) in
                self.PaymentView.removeFromSuperview()
                self.dimView.removeFromSuperview()
            }
        }
        
    }

    
    @IBAction func DismissPay(_ sender: Any) {
        handleDismiss()
    }
    @IBAction func SliderValue(_ sender: UISlider) {
        self.numberLabel.text = String(Int(sender.value))
    }
    @IBAction func CancelPay(_ sender: Any) {
        handleDismiss()
    }
    @IBAction func ConfirmPay(_ sender: Any) {
        let purchasedTicket = Int(SliderTickets.value)
        let userID = FIRAuth.auth()?.currentUser?.uid
        ref.child(self.passKey).child("Raffle Pool").observeSingleEvent(of: .value, with: {
            snapshot in
            if snapshot.hasChild(userID!){
                let value = snapshot.value as? NSDictionary
                let alreadyIn = value![userID!] as! Int
                if purchasedTicket > 5 - alreadyIn {
                    SVProgressHUD.showError(withStatus: "You already entered \(alreadyIn) tikects, the maximum is 5.")
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2, execute: {
                        SVProgressHUD.dismiss()
                    })
                    
                }
                else {
                    let value = purchasedTicket+alreadyIn
                    let post = [userID!: value] as [AnyHashable: Any]
                    self.ref.child(self.passKey).child("Raffle Pool").updateChildValues(post)
                    self.handleUpdateTickets(Tickets: purchasedTicket)
                }
            }
            else {
                self.ref.child(self.passKey).child("Raffle Pool").updateChildValues([userID!: purchasedTicket])
                self.handleUpdateTickets(Tickets: purchasedTicket)
            }
        })
        
    }
    

    func checklikes() {
        let child = self.passKey
        let userID = FIRAuth.auth()?.currentUser?.uid
        self.ref.child(child!).child("Liked Users").observeSingleEvent(of: .value, with: {
            snapshot in
            if snapshot.hasChild(userID!){
                self.check = true
            }
            else {
                self.check = false
            }
            
        })
    }
    func handlelike() {

        let checklikefunction = CheckLikeFuncionts()
        checklikefunction.handlelike(passKey: self.passKey , check: self.check)
        if self.check == true {
            self.check = false
        }
        else {
            self.check = true
        }

    }
    
    func handleUpdateTickets(Tickets: Int) {
        let location = "Users"
        let userID = FIRAuth.auth()?.currentUser?.uid
        self.ref.child(location).child(userID!).observeSingleEvent(of: .value, with: {
            snapshot in
            let value = snapshot.value as? NSDictionary
            var hastickets = value!["Tickets"] as! Int
            hastickets = hastickets - Tickets
            DataBaseStructure().updateUserDatabase(location: location, userID: userID!, post: ["Tickets": hastickets])
        })
        self.handleDismiss()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.1, execute: {
            SettingsLauncher.showAlerts(title: "Congragulations!", message: "You've entered \(Tickets) tickets for \(self.passLabel!), enjoy!", handler: nil, controller: self)
        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
