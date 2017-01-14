//
//  SignInVC.swift
//  DevslopesSocial
//
//  Created by Juan M Mariscal on 1/12/17.
//  Copyright © 2017 Juan M Mariscal. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class SignInVC: UIViewController {
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func facebookBtnTapped(_ sender: AnyObject) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                
                print("TEST: unable to authenticate with Facebook - \(error)")
            } else if result?.isCancelled == true {
                
                print("TEST: User cancelled Facebook authentication")
            } else {
                
                print("TEST: Successfully authenticated with Facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            
            if error != nil {
                
                print("TEST: Unable to authenticate with Firebase - \(error)")
            } else {
                
                print("TEST: Succesfully auth with Firebase")
            }
        })
    }
    

}

