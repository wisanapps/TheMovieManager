//
//  ListsTableViewController.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/26/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit

// MARK: - WatchlistViewController: UIViewController

class WatchlistViewController: UIViewController {
    
    // MARK: Properties
    
    var movies: [TMDBMovie] = [TMDBMovie]()
    
    // MARK: Outlets
    
    @IBOutlet weak var moviesTableView: UITableView!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create and set the logout button
        parent!.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(logout))
    }//end override func viewDidLoad()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        TMDBClient.sharedInstance().getWatchlistMovies { (movies, error) in
            if let movies = movies {
                self.movies = movies
                performUIUpdatesOnMain {
                    self.moviesTableView.reloadData()
                }
            } else {
                print(error ?? "empty error")
            }
        }
        
    }//end override func viewWillAppear(_ animated: Bool)
    
    // MARK: Logout
    
    @objc func logout() {
        dismiss(animated: true, completion: nil)
    }
    
}//end class WatchlistViewController: UIViewController


// MARK: - WatchlistViewController: UITableViewDelegate, UITableViewDataSource

extension WatchlistViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /* Get cell type */
        let cellReuseIdentifier = "WatchlistTableViewCell"
        let movie = movies[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        
        /* Set cell defaults */
        cell?.textLabel!.text = movie.title
        cell?.imageView!.image = UIImage(named: "Film")
        cell?.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        
        if let posterPath = movie.posterPath {
            let _ = TMDBClient.sharedInstance().taskForGETImage(TMDBClient.PosterSizes.RowPoster, filePath: posterPath, completionHandlerForImage: { (imageData, error) in
                if let image = UIImage(data: imageData!) {
                    performUIUpdatesOnMain {
                        cell?.imageView!.image = image
                    }
                } else {
                    print(error ?? "empty error")
                }
            })
        }
        
        return cell!
    }//end func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }//end func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "MovieDetailViewController") as! MovieDetailViewController
        controller.movie = movies[(indexPath as NSIndexPath).row]
        navigationController!.pushViewController(controller, animated: true)
    }//end func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }//end func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
}
