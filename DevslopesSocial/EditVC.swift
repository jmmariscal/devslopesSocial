//
//  EditVC.swift
//  DevslopesSocial
//
//  Created by Juan M Mariscal on 1/30/17.
//  Copyright © 2017 Juan M Mariscal. All rights reserved.
//

import UIKit
import Firebase

class EditVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var profileImageAdd: CircleView!
    
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var profilePic: PostCell!
    var post: Post!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            profileImageAdd.image = image
            imageSelected = true
        } else {
            print("TEST: valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveBtnTapped(_ sender: AnyObject) {
        //Close keyboard
        //returnCaptionFieldToTop()
        
        guard let img = profileImageAdd.image, imageSelected == true else {
            print("TEST: An image must be selected")
            return
        }
        
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_PROFILE_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata,error) in
                if error != nil {
                    print("TEST: Unable to upload profile image to Firebase storage")
                } else {
                    print("TEST: Succesfully uploaded profile image to Firebase storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        
                        DataService.ds.REF_USER_CURRENT.child("profileImgUrl").setValue(url)
                        //Here im trying to set the new updated profile img to the UIImageView profileImg
                        FeedVC.imageCache.setObject(img, forKey: self.post.profileImgUrl as NSString)
                        self.profilePic.profileImg.image = img
                    }
                }
            }
        }
        
    }
    
    @IBAction func addProfileImageTapped(_ sender: AnyObject) {
        
        self.view.endEditing(true)
        //returnCaptionFieldToTop()
        
        present(imagePicker, animated: true, completion: nil)
    }




}
