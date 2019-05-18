//
//  AppDelegate.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        
        #if DEBUG
        print("Realm location: \(Realm.Configuration.defaultConfiguration.fileURL?.absoluteString ?? "")")
        #endif
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // DI
        let networkService: NetworkService = NetworkServiceImpl()
        let localStorage: LocalStorage = LocalStorageImpl()
        
        let listViewController = storyboard.instantiateViewController(withIdentifier: CountryListViewController.identifier) as! CountryListViewController        
        
        let presenter: CountryListPresenter = CountryListPresenterImpl(
            view: listViewController,
            networkService: networkService,
            localStorage: localStorage
        )
        
        listViewController.presenter = presenter
        
        window.rootViewController = UINavigationController(rootViewController: listViewController) 
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

