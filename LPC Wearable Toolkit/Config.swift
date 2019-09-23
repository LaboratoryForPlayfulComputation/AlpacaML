//
//  Config.swift
//  LPC Wearable Toolkit
//
//  Created by sapols on 17/09/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

// Set this to the machine's address which runs the signaling server
//fileprivate let defaultSignalingServerUrl = URL(string: "ws://127.0.0.1:8080")!      //localhost
//fileprivate let defaultSignalingServerUrl = URL(string: "wss://connect.websocket.in/alpacaml_in?room_id=2")! //websocket.in
fileprivate let defaultSignalingServerUrl = URL(string: "ws://10.201.46.164:8080")! //personal server


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
