//
//  TwitterClient.swift
//  twitter
//
//  Created by Niaz Jalal on 9/28/14.
//  Copyright (c) 2014 Niaz Jalal. All rights reserved.
//

import UIKit

let twitterBaseURL = NSURL(string: "https://api.twitter.com")
let twitterConsumerKey = "XXXXXX"
let twitterConsumerSecret = "XXXXXX"

class TwitterClient: BDBOAuth1RequestOperationManager {
   
    var loginCompletion: ((user: User?, error: NSError?) -> ())?
    
    class var sharedInstance: TwitterClient {
        
        struct Static {
            static let instance = TwitterClient(baseURL: twitterBaseURL, consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret)
        }
        
        return Static.instance
    }
    
    func homeTimelineWithParams(params: NSDictionary?, completion: (tweets: [Tweet]?, error: NSError?) -> ()) {
        
        self.GET("1.1/statuses/home_timeline.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
            
            //println("home timeline: \(response)")
            var tweets = Tweet.tweetsWithArray(response as [NSDictionary])
            
            completion(tweets: tweets, error: nil)
        }, failure: { (operation: AFHTTPRequestOperation!, error:NSError!) -> Void in
                
            println("Error getting current user home timeline")
            
            completion(tweets: nil, error: error)
        })
    }
    
    func tweetWithCompletion(tweetText: String, completion: (tweet: Tweet?, error: NSError?) -> ()) {
        
        var tweetParams: NSDictionary = ["status": tweetText]
        self.statusWithCompletion(tweetParams, completion)
    }

    func tweetReplyWithCompletion(tweetText: String, replyAddress: User, completion: (tweet: Tweet?, error: NSError?) -> ()) {
        
        //var tweetParams: NSDictionary = ["status": tweetText, "in_reply_to_status_id": replyAddress.id]
        
        //self.statusWithCompletion(tweetParams, completion)
    }
    
    private func statusWithCompletion(params: NSDictionary?, completion: (tweet: Tweet?, error: NSError?) -> ()) {
        
        self.POST("1.1/statuses/update.json", parameters: params,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                
                var tweet = Tweet(dictionary: (response as NSDictionary))
                completion(tweet: tweet, error: nil)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            
            completion(tweet: nil, error: error)
        })
    }
    
    func loginWithCompletion(completion: (user: User?, error: NSError?) -> ()) {
        
        loginCompletion = completion
        
        // Fetch request token & redirect to authorization page
        // NAJ: In Use, commented out in view controller
        TwitterClient.sharedInstance.requestSerializer.removeAccessToken()
        TwitterClient.sharedInstance.fetchRequestTokenWithPath("oauth/request_token", method: "GET", callbackURL: NSURL(string: "twitterswiftclient://oauth"), scope: nil, success: { (requestToken: BDBOAuthToken!) -> Void in
            println("Got the request token")
            
            var authURL = NSURL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(requestToken.token)")
            
            UIApplication.sharedApplication().openURL(authURL)
            
        }) { (error: NSError!) -> Void in
            println("Failed to get request token")
            
            self.loginCompletion?(user: nil, error: error)
        }
    }
    
    func openURL(url: NSURL) {
       
        // NAJ: In Use: commented out in app delegate openURL() call
        fetchAccessTokenWithPath("oauth/access_token", method: "POST", requestToken: BDBOAuthToken(queryString: url.query), success: { (access_token: BDBOAuthToken!) -> Void in
            
            println("Got the access token!")
            
            TwitterClient.sharedInstance.requestSerializer.saveAccessToken(access_token)
            
            TwitterClient.sharedInstance.GET("1.1/account/verify_credentials.json", parameters: nil, success: { (operation:AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                
                //println("user: \(response)")
                var user = User(dictionary: response as NSDictionary)
                User.currentUser = user
                //println("user: \(user.name)")
                
                self.loginCompletion?(user: user, error: nil)
            }, failure: { (operation: AFHTTPRequestOperation!, error:NSError!) -> Void in
                    
                println("Error getting current user")
                    
                self.loginCompletion?(user: nil, error: error)
            })
            
            TwitterClient.sharedInstance.GET("1.1/statuses/home_timeline.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                
                println("home timeline: \(response)")
                var tweets = Tweet.tweetsWithArray(response as [NSDictionary])
                
                for tweet in tweets {
                    
                    //println("text: \(tweet.text) created: \(tweet.createdAt)")
                }
            }, failure: { (operation: AFHTTPRequestOperation!, error:NSError!) -> Void in
                    
                println("Error getting current user home timeline")
            })
            }) { (error: NSError!) -> Void in
                
                println("Failed to receive access token")
                
                self.loginCompletion?(user: nil, error: error)
        }
    }
}
