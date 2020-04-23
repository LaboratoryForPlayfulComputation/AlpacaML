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
    
    func login(pairId: String) {
        
        let message = Message.login(pairId)
        do {
            let loginMessage = try self.encoder.encode(message)
            socket.write(data: loginMessage)
        } catch {
            print("Could not encode login message for: \(pairId). Received Error: \(error)")
        }
    }
    
    func send(sdp rtcSdp: RTCSessionDescription, pairId: String) {
        let message = Message.sdp(SessionDescription(from: rtcSdp, with: pairId))
        do {
            let dataMessage = try self.encoder.encode(message)
            print(dataMessage.base64EncodedString())
            self.socket.write(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate, pairId: String) { // try adding pairID here , also try to figure out when this gets called
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate, with: pairId))
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
        print("received data")
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
        default :
            print("Received message of unknown type \(message)")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let data = text.data(using: .utf8)!
        print("received string")
        
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
        default :
            print("Received message of unknown type \(message)")
        }
    }
}
