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
                //print(requestToken!)
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
                completionHandlerForSession(false, nil,"Login Failed (Session ID)")
                return
            }
            
            guard let successStatus = data[JSONResponseKeys.StatusSuccess] as? Bool, successStatus == true else {
                completionHandlerForSession(false, nil,"Login Failed (Session ID)")
                return
            }
            
            guard let sessionID = data[JSONResponseKeys.SessionID] as? String else {
                completionHandlerForSession(false, nil,"Login Failed (Session ID)")
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
                completionHandlerForUserID(false, nil,"Login Failed (User ID)")
                return
            }
            
            guard let userID = data[JSONResponseKeys.UserID] as? Int else {
                completionHandlerForUserID(false, nil,"Login Failed (User ID)")
                return
            }
            
            completionHandlerForUserID(true, userID, nil)
        }
    }
    
    // MARK: GET Convenience Methods
    
    func getFavoriteMovies(_ completionHandlerForFavMovies: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        let apiParameters = [TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        var mutableMethod = Methods.AccountIDFavoriteMovies
        mutableMethod = substituteKeyInMethod(mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(TMDBClient.sharedInstance().userID!))!
        
        /* 2. Make the request */
        let _ = taskForGETMethod(mutableMethod, parameters: apiParameters as [String : AnyObject]) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            guard error == nil else {
                completionHandlerForFavMovies(nil, error)
                return
            }
            guard let jsonObject = results else {
                completionHandlerForFavMovies(nil, NSError(domain: "getFavoriteMovies", code: 1, userInfo: [NSLocalizedDescriptionKey: "No result returned"]))
                return
            }
            guard let jsonMovies = jsonObject[TMDBClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]] else {
                completionHandlerForFavMovies(nil, NSError(domain: "getFavoriteMovies", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not parse getFavoriteMovies"]))
                return
            }
            
            let movies = TMDBMovie.moviesFromResults(jsonMovies)
            completionHandlerForFavMovies(movies, nil)
        }
    }
    
    func getWatchlistMovies(_ completionHandlerForWatchlist: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        let apiParameters = [ ParameterKeys.SessionID: self.sessionID]
        
        _ = self.taskForGETMethod(TMDBClient.Methods.AccountIDWatchlistMovies.replacingOccurrences(of: "{id}", with: String(self.userID!)),
                                  parameters: apiParameters as [String : AnyObject]) { (result, error) in
            
            guard error == nil else {
                completionHandlerForWatchlist(nil, error)
                return
            }
            
            guard let result = result as? [String: AnyObject] else {
                completionHandlerForWatchlist(nil,
                                              NSError(domain: "getWatchlistMovies",
                                                      code: 1,
                                                      userInfo: [NSLocalizedDescriptionKey : "Canot convert to [String: AnyObject]"]))
                return
            }
            
            guard let movies = result[JSONResponseKeys.MovieResults]  as? [[String: AnyObject]] else {
                completionHandlerForWatchlist(nil,
                                              NSError(domain: "getWatchlistMovies",
                                                      code: 1,
                                                      userInfo: [NSLocalizedDescriptionKey: "Cannot find value for key '\(JSONResponseKeys.MovieResults)'"]))
                return
            }
                                    
            let tmdbMovies = TMDBMovie.moviesFromResults(movies)
            completionHandlerForWatchlist(tmdbMovies, nil)
        }
    }
    
    func getMoviesForSearchString(_ searchString: String, completionHandlerForMovies: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionDataTask? {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        let apiParameters = [TMDBClient.ParameterKeys.Query: searchString]
        
        /* 2. Make the request */
        let task = taskForGETMethod(Methods.SearchMovie, parameters: apiParameters as [String : AnyObject]) { (results, error) in
            
             /* 3. Send the desired value(s) to completion handler */
            guard error == nil else {
                completionHandlerForMovies(nil, error)
                return
            }
            
            guard let jsonObject = results as? [String: AnyObject] else {
                completionHandlerForMovies(nil, NSError(domain: "getMoviesForSearchString parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert to [String: AnyObject]"]))
                return
            }
            
            guard let jsonMovies = jsonObject[TMDBClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]] else {
                completionHandlerForMovies(nil, NSError(domain: "getMoviesForSearchString parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getMoviesForSearchString"]))
                return
            }
            
            let movies = TMDBMovie.moviesFromResults(jsonMovies)
            completionHandlerForMovies(movies, nil)
        }
        
        return task
    }
    
    func getConfig(_ completionHandlerForConfig: @escaping (_ didSucceed: Bool, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [String:AnyObject]()
        
        /* 2. Make the request */
        let _ = taskForGETMethod(Methods.Config, parameters: parameters as [String:AnyObject]) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForConfig(false, error)
            } else if let newConfig = TMDBConfig(dictionary: results as! [String:AnyObject]) {
                self.config = newConfig
                completionHandlerForConfig(true, nil)
            } else {
                completionHandlerForConfig(false, NSError(domain: "getConfig parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getConfig"]))
            }
        }

    }//end func getConfig(_ completionHandlerForConfig: @escaping (_ didSucceed: Bool, _ error: NSError?) -> Void)
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(_ movie: TMDBMovie, favorite: Bool, completionHandlerForFavorite: @escaping (_ result: Int?, _ error: NSError?) -> Void)  {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [TMDBClient.ParameterKeys.SessionID : TMDBClient.sharedInstance().sessionID!]
        var mutableMethod: String = Methods.AccountIDFavorite
        mutableMethod = substituteKeyInMethod(mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(TMDBClient.sharedInstance().userID!))!
        let jsonBody = "{\"\(TMDBClient.JSONBodyKeys.MediaType)\": \"movie\",\"\(TMDBClient.JSONBodyKeys.MediaID)\": \"\(movie.id)\",\"\(TMDBClient.JSONBodyKeys.Favorite)\": \(favorite)}"
        
        /* 2. Make the request */
        let _ = taskForPOSTMethod(mutableMethod, parameters: parameters as [String:AnyObject], jsonBody: jsonBody) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForFavorite(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                    completionHandlerForFavorite(results, nil)
                } else {
                    completionHandlerForFavorite(nil, NSError(domain: "postToFavoritesList parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse postToFavoritesList"]))
                }
            }
        }
    }//end func postToFavorites(_ movie: TMDBMovie, favorite: Bool, completionHandlerForFavorite: @escaping (_ result: Int?, _ error: NSError?) -> Void)
    
    func postToWatchlist(_ movie: TMDBMovie, watchlist: Bool, completionHandlerForWatchlist: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        let apiParameters = [TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID!]
        var method: String = Methods.AccountIDWatchlist
        method = substituteKeyInMethod(method, key: TMDBClient.URLKeys.UserID, value: String(TMDBClient.sharedInstance().userID!))!
     
        let jsonBody = "{\"\(TMDBClient.JSONBodyKeys.MediaType)\": \"movie\",\"\(TMDBClient.JSONBodyKeys.MediaID)\": \"\(movie.id)\",\"\(TMDBClient.JSONBodyKeys.Watchlist)\": \(watchlist)}"
        
        let _ = taskForPOSTMethod(method, parameters: apiParameters as [String : AnyObject], jsonBody: jsonBody) { (results, error) in
            guard error == nil else {
                completionHandlerForWatchlist(nil, error)
                return
            }
            
            guard let jsonObject =  results as? [String: AnyObject] else {
                completionHandlerForWatchlist(nil, error)
                return
            }
            
            guard let success = jsonObject[TMDBClient.JSONResponseKeys.StatusCode] as? Int else {
                completionHandlerForWatchlist(nil, error)
                return
            }
            
            completionHandlerForWatchlist(success, nil)
        }
    }
}
