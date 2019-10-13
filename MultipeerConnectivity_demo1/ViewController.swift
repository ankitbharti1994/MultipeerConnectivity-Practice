//
//  ViewController.swift
//  MultipeerConnectivity_demo1
//
//  Created by ankit bharti on 12/10/19.
//  Copyright © 2019 ankit kumar bharti. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // MARK: - IBOutlet Properties
    
    @IBOutlet private weak var connectionlabel: UILabel!
    
    // MARK: - Properties
    private let colorService = ColorService()
    
    // MARK: - Controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorService.delegate = self
    }
    
    // MARK: - IBAction methods
    
    @IBAction private func redTapped(_ sender: Any) {
        self.change(color: .systemRed)
        colorService.send(colorName: "red")
    }
    
    @IBAction private func greenTapped(_ sender: Any) {
        self.change(color: .systemIndigo)
        colorService.send(colorName: "Indigo")
    }
    
    private func change(color: UIColor) {
        self.view.backgroundColor = color
        self.connectionlabel.textColor = .white
    }
}

extension ViewController: ColorServiceDelegate {
    func connectedDevicesChanged(manager: ColorService, state: String, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            switch state {
            case "Connected":
                self.connectionlabel.text = "\(state): \(connectedDevices.first ?? "")"
                
            default:
                self.connectionlabel.text = state
            }
        }
    }
    
    func colorChanged(manager: ColorService, colorString: String) {
        OperationQueue.main.addOperation {
            switch colorString {
            case "red":
                self.change(color: .systemRed)
                
            case "Indigo":
                self.change(color: .systemIndigo)
                
            default:
                NSLog("%@", "Unknown color value received: \(colorString)")
            }
        }
    }
}
