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
import SwiftKeychainWrapper


class SignInVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pswdField: UITextField!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("TEST: ID found in keychain")
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
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
                if let user = user{
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
                
            }
        })
    }
    
    @IBAction func signBtnTapped(_ sender: AnyObject) {
        
        if let email = emailField.text, let pswrd = pswdField.text {
            
            FIRAuth.auth()?.signIn(withEmail: email, password: pswrd, completion: { (user, error) in
                if error == nil {
                    
                    print("TEST: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    
                    FIRAuth.auth()?.createUser(withEmail: email, password: pswrd, completion: { (user, error) in
                        if error != nil {
                            
                            print("TEST: Unable to authenticate with Firebase using email")
                        } else {
                            
                            print("TEST: Succesfully authenticate with Firebase using Email")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        
        KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("TEST: Data saved to keychain")
        performSegue(withIdentifier: "goToFeed", sender: nil)
    }

}
