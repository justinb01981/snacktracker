//
//  ViewController.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.white
        
        let enterButton = UIButton()
        enterButton.setTitle("Enter", for: .normal)
        enterButton.setTitleColor(UIColor.black, for: .normal)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterButton)
        
        enterButton.addConstraints([
            enterButton.widthAnchor.constraint(equalToConstant: 150.0),
            enterButton.heightAnchor.constraint(equalToConstant: 64.0)
        ])
        
        let logButton = UIButton()
        logButton.setTitle("Log", for: .normal)
        logButton.setTitleColor(UIColor.black, for: .normal)
        logButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logButton)
        
        logButton.addConstraints([
            logButton.widthAnchor.constraint(equalToConstant: 150.0),
            logButton.heightAnchor.constraint(equalToConstant: 64.0)
        ])
        
        view.addConstraints([
            enterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -250.0),
            logButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150.0)
        ])
        
        enterButton.addTarget(self, action: #selector(onEnterButton), for: .touchUpInside)
        logButton.addTarget(self, action: #selector(onLogButton), for: .touchUpInside)
    }

    @objc func onEnterButton(_ sender: Any) {
        let enterVC = EnterViewController()
        
        navigationController?.pushViewController(enterVC, animated: true)
    }
    
    @objc func onLogButton(_ sender: Any) {
        let logVC = LogViewController()
        
        navigationController?.pushViewController(logVC, animated: true)
    }
}

