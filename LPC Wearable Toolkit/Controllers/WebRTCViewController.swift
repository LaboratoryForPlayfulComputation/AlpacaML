//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class WebRTCViewController: UIViewController {

    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    
    @IBOutlet private weak var serverUrlLabel: UILabel?
    @IBOutlet private weak var signalingStatusLabel: UILabel?
    @IBOutlet private weak var localSdpStatusLabel: UILabel?
    @IBOutlet private weak var localCandidatesLabel: UILabel?
    @IBOutlet private weak var remoteSdpStatusLabel: UILabel?
    @IBOutlet private weak var remoteCandidatesLabel: UILabel?
    @IBOutlet private weak var webRTCStatusLabel: UILabel?
    
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.signalingStatusLabel?.text = "Connected"
                    self.signalingStatusLabel?.textColor = UIColor.green
                }
                else {
                    self.signalingStatusLabel?.text = "Not connected"
                    self.signalingStatusLabel?.textColor = UIColor.red
                }
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSdpStatusLabel?.text = self.hasLocalSdp ? "✅" : "❌"
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesLabel?.text = "\(self.localCandidateCount)"
            }
        }
    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesLabel?.text = "\(self.remoteCandidateCount)"
            }
        }
    }
    
    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.signalClient = appDelegate.signalClient
        self.webRTCClient = appDelegate.webRTCClient
        super.init(nibName: String(describing: WebRTCViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.signalClient = appDelegate.signalClient
        self.webRTCClient = appDelegate.webRTCClient
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WebRTC Demo"
        self.signalingConnected = false
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
        self.localCandidateCount = 0
        self.remoteCandidateCount = 0
        self.webRTCStatusLabel?.text = /*"New (" +*/ self.webRTCClient.pairId /*+ ")"*/
        
        self.signalClient.connect()
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        
        self.webRTCClient.muteAudio()
        self.webRTCClient.speakerOff()
        self.serverUrlLabel?.text = self.signalClient.getServerUrl()
    }
    
    @IBAction private func offerDidTap(_ sender: UIButton) {
        self.webRTCClient.offer { (sdp) in
            self.hasLocalSdp = true
            self.signalClient.send(sdp: sdp)
        }
    }
    
    @IBAction private func answerDidTap(_ sender: UIButton) {
        self.webRTCClient.answer { (localSdp) in
            self.hasLocalSdp = true
            self.signalClient.send(sdp: localSdp)
        }
    }
    
    @IBAction func sendDataDidTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Send a message to your Scratch project",
                                      message: "This mimics the messages your gestures will send.",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Message to send"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
            guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
                return
            }
            self?.webRTCClient.sendData(dataToSend)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension WebRTCViewController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            self.hasRemoteSdp = true
        }
        
        //Wait 1 second then answer the offer if the pairIds match (case insensitive)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if (self.webRTCClient.pairId.caseInsensitiveCompare(self.webRTCClient.remotePairId) == .orderedSame) {
                print("pairId match!")
                self.webRTCClient.answer { (localSdp) in
                    self.hasLocalSdp = true
                    self.signalClient.send(sdp: localSdp)
                }
            }
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate")
        self.remoteCandidateCount += 1
        self.webRTCClient.set(remoteCandidate: candidate)
    }
}

extension WebRTCViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        self.localCandidateCount += 1
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatusLabel?.text = /*state.description.capitalized + " (" +*/ self.webRTCClient.pairId /*+ ")"*/
            self.webRTCStatusLabel?.textColor = textColor
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            let alert = UIAlertController(title: "Incoming Message", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

