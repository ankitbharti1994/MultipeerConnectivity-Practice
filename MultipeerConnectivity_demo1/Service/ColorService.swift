//
//  ColorService.swift
//  MultipeerConnectivity_demo1
//
//  Created by ankit bharti on 12/10/19.
//  Copyright © 2019 ankit kumar bharti. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ColorServiceDelegate: AnyObject {
    func connectedDevicesChanged(manager : ColorService, state: String, connectedDevices: [String])
    func colorChanged(manager : ColorService, colorString: String)
}

extension MCSessionState {
    var stringValue: String {
        switch self {
        case .notConnected:
            return "Not Connected"
            
        case .connecting:
            return "Connecting"
            
        case .connected:
            return "Connected"
            
        @unknown default:
            fatalError("handle the all cases.")
        }
    }
}

final class ColorService: NSObject {
    // MARK: - Constants
    
    /// Service type must be a unique string, at most 15 characters long
    /// and can contain only ASCII lowercase letters, numbers and hyphens.
    private let ColorServiceType = "example-color"
    
    private lazy var session: MCSession = {
        let mcSession = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        return mcSession
    }()
    
    weak var delegate : ColorServiceDelegate?
    
    // MARK: - Properties
    
    /// The displayName will be visible to other devices.
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    /// To advertise the service.
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    /// Scan the advertising services
    private let serviceBrowser: MCNearbyServiceBrowser
    
    // MARK: - Initilizer & De-Initilizer
    override init() {
        // advertising
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ColorServiceType)
        
        // scanning
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ColorServiceType)
        
        super.init()
        
        // advertising
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        // scanning
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(colorName : String) {
        print("sendColor: \(colorName) to \(session.connectedPeers.count) peers")

        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(colorName.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                print("Error for sending: \(error)")
            }
        }

    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ColorService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error.localizedDescription)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("received invitation from \(peerID) " + #function)
        invitationHandler(true, self.session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ColorService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error.localizedDescription + " " + #function)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("peer found: \(peerID) with info: \(info ?? [:])")
        print("Inviting peer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: .infinity)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("connection lost with peer: \(peerID)")
    }
}

// MARK: - MCSessionDelegate
extension ColorService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue)")
        self.delegate?.connectedDevicesChanged(manager: self,
                                               state: state.stringValue,
                                               connectedDevices: session.connectedPeers.map {
                                                    $0.displayName
                                                }
                                            )
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("\(peerID) ", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.colorChanged(manager: self, colorString: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("\(peerID) ", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("\(peerID) ", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("\(peerID) ", "didFinishReceivingResourceWithName")
    }
}
