//
//  Config.swift
//  LPC Wearable Toolkit
//
//  Created by sapols on 17/09/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

// Set this to the machine's address which runs the signaling server
//fileprivate let defaultSignalingServerUrl = URL(string: "ws://Shawns-MacBook-Pro.local:8080")! //personal server
fileprivate let defaultSignalingServerUrl = URL(string: "ws://scratchpaca.playfulcomputation.group:1230")! //Ben's server


// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]

struct Config {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]
    
    static let `default` = Config(signalingServerUrl: defaultSignalingServerUrl, webRTCIceServers: defaultIceServers)
}
