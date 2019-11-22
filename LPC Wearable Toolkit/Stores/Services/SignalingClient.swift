//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import Starscream
import WebRTC

protocol SignalClientDelegate: class {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    
    private var socket: WebSocket //used to be "private let"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    weak var delegate: SignalClientDelegate?
    
    init(serverUrl: URL) {
        self.socket = WebSocket(url: serverUrl)
        
    }
    func connect() {
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription) {
        let message = Message.sdp(SessionDescription(from: rtcSdp))
        do {
            let dataMessage = try self.encoder.encode(message)
            self.socket.write(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
        do {
            let dataMessage = try self.encoder.encode(message)
            self.socket.write(data: dataMessage)
            print(dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }
    
    //Return the URL of the signaling server
    func getServerUrl() -> String {
        return self.socket.currentURL.absoluteString
    }
    
    //Change the URL of the signaling server (and reconnect)
    func setServerUrl(urlStr: String) {
        let serverUrl = URL(string: urlStr)
        self.socket = WebSocket(url: serverUrl!)
        self.socket.connect() //This connects to the new WebSocket server but doesn't update the view. Or the rest of the WebRTC stack, I think
        self.delegate?.signalClientDidConnect(self) //TODO: try this approach
        //websocketDidConnect(socket: socket) //this sets "Signaling status" in the view to "Connected" but there are still problems (never able to flip Remote SDP or get Remote Candidates)
    }
}


extension SignalingClient: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        self.delegate?.signalClientDidConnect(self)
        debugPrint("Connected to signaling server")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.delegate?.signalClientDidDisconnect(self)
        
        // try to reconnect every two seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            debugPrint("Trying to reconnect to signaling server...")
            self.socket.connect()
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        let message: Message
        do {
            message = try self.decoder.decode(Message.self, from: data)
        }
        catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message {
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let data = text.data(using: .utf8)!
        
        // look for pairId from Scratch
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let jsonArray = json as? [String: Any] {
            if let id = jsonArray["pairId"] as? String {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.webRTCClient.remotePairId = id
            }
        }
        
        // try to interpret message as candidate/sdp
        let message: Message
        do {
            message = try self.decoder.decode(Message.self, from: data)
        }
        catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message {
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        }
    }
}
