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


class SignInVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: FancyTextField!
    @IBOutlet weak var pswdField: FancyTextField!
    @IBOutlet weak var signInTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var signInStackView: UIStackView!
    @IBOutlet weak var facebookLogo: RoundButton!
    
    var signInTopConstraintConstant: CGFloat = 85.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Listen for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector (emailKeyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        //Refrence to caption text field to hide keyboard
        self.emailField.delegate = self
        self.pswdField.delegate = self
        
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
    
    // Hide keyboard when user touches outside keybaord
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.facebookLogo.isHidden = false
        self.view.endEditing(true)
        returnSignInCaptionFieldToTop()
    }
    
    // Hide keyboard when user presses return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.facebookLogo.isHidden = false
        emailField.resignFirstResponder()
        pswdField.resignFirstResponder()
        returnSignInCaptionFieldToTop()
        return (true)
    }
    
    // Return caption field back to the top of the screen
    func returnSignInCaptionFieldToTop() {
        
        UIView.animate(withDuration: 0.5) {
            
            self.signInTopConstraint.constant = self.signInTopConstraintConstant
            self.view.layoutIfNeeded()
        }
    }
    
    func emailKeyboardWillShow(notification:NSNotification) {
        
        self.facebookLogo.isHidden = true
        
        if let info = notification.userInfo {
            
            let rect = (info["UIKeyboardFrameEndUserInfoKey"] as! NSValue).cgRectValue
            
            //Find our target Y
            let targetY = view.frame.size.height - rect.height - 90 - emailField.frame.size.height
            
            //Find out where the stackview is relative to the frame
            let textFieldY = signInStackView.frame.origin.y + emailField.frame.origin.y
            
            let difference = targetY - textFieldY
            
            let targetOffsetForTopConstraint = signInTopConstraint.constant + difference
            
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.25, animations: {
                
                self.signInTopConstraint.constant = targetOffsetForTopConstraint
                self.view.layoutIfNeeded()
            })
        }
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
