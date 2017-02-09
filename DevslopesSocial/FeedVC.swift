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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var captionField: FancyTextField!
    @IBOutlet weak var captionFieldTopConstraint: NSLayoutConstraint!

    var captionFieldTopConstraintConstant:CGFloat = 16.0

    @IBOutlet weak var captionFieldStackView: UIStackView!
    @IBOutlet weak var captionFieldOutterView: FancyView!
    
    var posts = [Post]()
    var postRef: PostCell!
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        //Observer to reload Tableview
        NotificationCenter.default.addObserver(self, selector: Selector(("loadList:")), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        //Listen for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector (keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        //Refrence to caption text field to hide keyboard
        self.captionField.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    print("SNAP: \(snap)")
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            
            self.tableView.reloadData()
        })
    }
    
    func loadList(notification: NSNotification) {
        
        //load data
        self.tableView.reloadData()
    }
    
    // Hide keyboard when user touches outside keybaord
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        returnCaptionFieldToTop()
    }
    
    // Hide keyboard when user presses return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        captionField.resignFirstResponder()
        returnCaptionFieldToTop()
        return (true)
    }
    
    // Return caption field back to the top of the screen
    func returnCaptionFieldToTop() {
        
        UIView.animate(withDuration: 0.5) {
            
            self.captionFieldTopConstraint.constant = self.captionFieldTopConstraintConstant
            self.view.layoutIfNeeded()
        }
    }
    
    
    func keyboardWillShow(notification:NSNotification) {
        
        if let info = notification.userInfo {
            
            let rect = (info["UIKeyboardFrameEndUserInfoKey"] as! NSValue).cgRectValue
            
            //Find our target Y
            let targetY = view.frame.size.height - rect.height - 16 - captionField.frame.size.height
            
            //Find out where the stackview is relative to the frame
            let textFieldY = captionFieldOutterView.frame.origin.y + captionFieldStackView.frame.origin.y + captionField.frame.origin.y
            
            let difference = targetY - textFieldY
            
            let targetOffsetForTopConstraint = captionFieldTopConstraint.constant + difference
            
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.25, animations: { 
                
                self.captionFieldTopConstraint.constant = targetOffsetForTopConstraint
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString), let profileImg = FeedVC.imageCache.object(forKey: post.profileImgUrl as NSString) {
                cell.configureCell(post: post, img: img, profileImg: profileImg)
                
            }else { cell.configureCell(post: post)}
            return cell
        } else {return PostCell()}
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            imageAdd.image = image
            //profileImgAdd.image = image
            imageSelected = true
        } else {
            print("TEST: valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func postBtnTapped(_ sender: AnyObject) {
        
        self.view.endEditing(true)
        returnCaptionFieldToTop()
        
        guard let caption =  captionField.text, caption != "" else {
            print("TEST: Caption must be entered")
            return
        }
        guard let img = imageAdd.image, imageSelected == true else {
            print("TEST: An image must be selected")
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata,error) in
                if error != nil {
                    print("TEST: Unable to upload image toFirebase storage")
                } else {
                    print("TEST: Succesfully uploaded image toFirebase storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
    }
    
    @IBAction func addImageTapped(_ sender: AnyObject) {
        
        self.view.endEditing(true)
        returnCaptionFieldToTop()
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    //Post to Firebase
    func postToFirebase(imgUrl: String) {
        
        let post: Dictionary<String, AnyObject> = [
        
        "caption": captionField.text! as AnyObject,
        "imageUrl": imgUrl as AnyObject,
        "likes": 0 as AnyObject
            ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }
    
    @IBAction func signOutTapped(_ sender: AnyObject) {
        let keychainResult = KeychainWrapper.standard.remove(key: KEY_UID)
        print("TEST: ID Removed from keychain \(keychainResult)")
        try! FIRAuth.auth()?.signOut()
        
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }

}





























