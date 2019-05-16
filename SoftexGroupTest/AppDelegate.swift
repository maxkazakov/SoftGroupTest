//
//  AppDelegate.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit

let networkService: NetworkService = NetworkServiceImpl()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        let listViewController = storyboard.instantiateViewController(withIdentifier: ListViewController.identifier) as! ListViewController        
        
        let presenter: ListPresenter = ListPresenterImpl(
            view: listViewController,
            networkService: networkService
        )
        
        listViewController.presenter = presenter
        
        window.rootViewController = UINavigationController(rootViewController: listViewController) 
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

