//
//  FeedVC.swift
//  DevslopesSocial
//
//  Created by Juan M Mariscal on 1/15/17.
//  Copyright © 2017 Juan M Mariscal. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func signOutTapped(_ sender: AnyObject) {
        let keychainResult = KeychainWrapper.standard.remove(key: KEY_UID)
        print("TEST: ID Removed from keychain \(keychainResult)")
        try! FIRAuth.auth()?.signOut()
        
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }

}
