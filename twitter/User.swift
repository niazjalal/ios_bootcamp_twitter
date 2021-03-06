//
//  User.swift
//  twitter
//
//  Created by Niaz Jalal on 9/28/14.
//  Copyright (c) 2014 Niaz Jalal. All rights reserved.
//

import UIKit

var _currentUser: User?
let currentUserKey = "kCurrentUserKey"
let userDidLoginNotification = "userDidLoginNotification"
let userDidLogoutNotification = "userDidLogoutNotification"

class User: NSObject {
    
    var dictionary: NSDictionary
    var name: String?
    var screenname: String?
    var profileImageURL: NSURL?
    var tagline: String?
    var id: Int?
    
    init(dictionary: NSDictionary) {
        
        self.dictionary = dictionary
        
        name = dictionary["name"] as? String
        screenname = dictionary["screen_name"] as? String
        println("SCREEN NAME: \(screenname)")
        profileImageURL = NSURL(string: dictionary["profile_image_url"] as String)
        println("IMAGE URL FROM USER: \(profileImageURL)")
        tagline = dictionary["description"] as? String
        id = dictionary["id"] as? Int
    }
    
    func logout() {
        
        User.currentUser = nil
        
        TwitterClient.sharedInstance.requestSerializer.removeAccessToken()
        
        NSNotificationCenter.defaultCenter().postNotificationName(userDidLogoutNotification, object: nil)
    }
    
    class var currentUser: User? {
        
        get {
            if _currentUser == nil {
        
                var data = NSUserDefaults.standardUserDefaults().objectForKey(currentUserKey) as? NSData
        
                if data != nil {
                    var dictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as NSDictionary
        
                    _currentUser = User(dictionary: dictionary)
                }
            }
        
            return _currentUser
        }
        
        set (user) {
            
            _currentUser = user
            
            if _currentUser != nil {
                var data = NSJSONSerialization.dataWithJSONObject(user!.dictionary, options: nil, error: nil)
                
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: currentUserKey)
            } else {
                NSUserDefaults.standardUserDefaults().setObject(nil, forKey: currentUserKey)
            }
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}
