//
//  CustomViewController.swift
//  Map
//
//  Created by Gary Chen on 17/4/2018.
//  Copyright © 2018 Gary Chen. All rights reserved.
//

import UIKit
import FirebaseAuth

class CustomViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftBarItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(logOutButtonTapped))
        navigationItem.leftBarButtonItem = leftBarItem
    }
    
    @objc func logOutButtonTapped() {
        do {
            try Auth.auth().signOut()
            navigationController?.popViewController(animated: true)
        } catch {
            print(error)
        }
    }


}
