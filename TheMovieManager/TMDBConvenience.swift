//
//  TMDBConvenience.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit
import Foundation

// MARK: - TMDBClient (Convenient Resource Methods)

extension TMDBClient {
    
    // MARK: Authentication (GET) Methods
    /*
        Steps for Authentication...
        https://www.themoviedb.org/documentation/api/sessions
        
        Step 1: Create a new request token
        Step 2a: Ask the user for permission via the website
        Step 3: Create a session ID
        Bonus Step: Go ahead and get the user id 😄!
    */
    func authenticateWithViewController(_ hostViewController: UIViewController, completionHandlerForAuth: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        // chain completion handlers for each request so that they run one after the other
        getRequestToken() { (success, requestToken, errorString) in
            
            if success {
                
                // success! we have the requestToken!
                print(requestToken!)
                self.requestToken = requestToken
                
                self.loginWithToken(requestToken, hostViewController: hostViewController) { (success, errorString) in
                    
                    if success {
                        self.getSessionID(requestToken) { (success, sessionID, errorString) in
                            
                            if success {
                                
                                // success! we have the sessionID!
                                self.sessionID = sessionID
                                
                                self.getUserID() { (success, userID, errorString) in
                                    
                                    if success {
                                        
                                        if let userID = userID {
                                            
                                            // and the userID 😄!
                                            self.userID = userID
                                        }
                                    }
                                    
                                    completionHandlerForAuth(success, errorString)
                                }
                            } else {
                                completionHandlerForAuth(success, errorString)
                            }
                        }
                    } else {
                        completionHandlerForAuth(success, errorString)
                    }
                }
            } else {
                completionHandlerForAuth(success, errorString)
            }
        }
    }
    
    private func getRequestToken(_ completionHandlerForToken: @escaping (_ success: Bool, _ requestToken: String?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        let apiParameters = [String: AnyObject]()
        
        _ = taskForGETMethod(Methods.AuthenticationTokenNew, parameters: apiParameters) { (result, error) in
            guard error == nil else {
                completionHandlerForToken(false, nil,"Login Failed (Request Token)")
                return
            }
            
            guard let data = result as? [String: AnyObject] else {
                completionHandlerForToken(false, nil,"Cannot covert data to [String: AnyObject]")
                return
            }
            
            guard let successStatus = data[JSONResponseKeys.StatusSuccess] as? Bool, successStatus == true else {
                completionHandlerForToken(false, nil,"The value for key '\(JSONResponseKeys.StatusSuccess)' is false")
                return
            }
            
            guard let token = data[JSONResponseKeys.RequestToken] as? String else {
                completionHandlerForToken(false, nil,"Cannot get value for key '\(JSONResponseKeys.RequestToken)'")
                return
            }
            
            completionHandlerForToken(true, token, nil)
        }
    }
    
    private func loginWithToken(_ requestToken: String?, hostViewController: UIViewController, completionHandlerForLogin: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        let authorizationURL = URL(string: "\(TMDBClient.Constants.AuthorizationURL)\(requestToken!)")
        let request = URLRequest(url: authorizationURL!)
        
        let webAuthViewController = hostViewController.storyboard!.instantiateViewController(withIdentifier: "TMDBAuthViewController") as! TMDBAuthViewController
        webAuthViewController.urlRequest = request
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandlerForView = completionHandlerForLogin
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        performUIUpdatesOnMain {
            hostViewController.present(webAuthNavigationController, animated: true, completion: nil)
        }
    }
    
    private func getSessionID(_ requestToken: String?, completionHandlerForSession: @escaping (_ success: Bool, _ sessionID: String?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        let apiParameters = [ParameterKeys.RequestToken: requestToken]
        
        _ = self.taskForGETMethod(Methods.AuthenticationSessionNew, parameters: apiParameters as [String : AnyObject]) { (result, error) in
            guard error == nil else {
                completionHandlerForSession(false, nil,"Login Failed (Session ID)")
                return
            }
            
            guard let data = result as? [String: AnyObject] else {
                completionHandlerForSession(false, nil,"Cannot covert data to [String: AnyObject]")
                return
            }
            
            guard let successStatus = data[JSONResponseKeys.StatusSuccess] as? Bool, successStatus == true else {
                completionHandlerForSession(false, nil,"The value for key '\(JSONResponseKeys.StatusSuccess)' is false")
                return
            }
            
            guard let sessionID = data[JSONResponseKeys.SessionID] as? String else {
                completionHandlerForSession(false, nil,"Cannot get value for key '\(JSONResponseKeys.SessionID)'")
                return
            }
            
            completionHandlerForSession(true, sessionID, nil)
        }
    }
    
    private func getUserID(_ completionHandlerForUserID: @escaping (_ success: Bool, _ userID: Int?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        let apiParameters = [ParameterKeys.SessionID: self.sessionID]
        
        _ = self.taskForGETMethod(Methods.Account, parameters: apiParameters as [String : AnyObject]) { (result, error) in
            guard error == nil else {
                completionHandlerForUserID(false, nil,"Login Failed (User ID)")
                return
            }
            
            guard let data = result as? [String: AnyObject] else {
                completionHandlerForUserID(false, nil,"Cannot covert data to [String: AnyObject]")
                return
            }
            
            guard let userID = data[JSONResponseKeys.UserID] as? Int else {
                completionHandlerForUserID(false, nil,"Cannot get value for key '\(JSONResponseKeys.UserID)'")
                return
            }
            
            completionHandlerForUserID(true, userID, nil)
        }
    }
    
    // MARK: GET Convenience Methods
    
    func getFavoriteMovies(_ completionHandlerForFavMovies: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getWatchlistMovies(_ completionHandlerForWatchlist: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getMoviesForSearchString(_ searchString: String, completionHandlerForMovies: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionDataTask? {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        return nil
    }
    
    func getConfig(_ completionHandlerForConfig: @escaping (_ didSucceed: Bool, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(_ movie: TMDBMovie, favorite: Bool, completionHandlerForFavorite: @escaping (_ result: Int?, _ error: NSError?) -> Void)  {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func postToWatchlist(_ movie: TMDBMovie, watchlist: Bool, completionHandlerForWatchlist: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
}
