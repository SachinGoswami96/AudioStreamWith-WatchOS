//
//  InterfaceController.swift
//  audioDemoStreamfor Watch WatchKit Extension
//
//  Created by Sachingiri Goswami on 22/11/22.
//  Copyright © 2022 Harshal Jadhav. All rights reserved.
//

import WatchKit
import Foundation
import MediaPlayer
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var btnPlay: WKInterfaceButton!
    var session = WCSession.default
    var isPaused = true
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        setWatchSession()
    }
    
    func setWatchSession(){
        if WCSession.isSupported(){
            session.delegate =  self
            session.activate()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    @IBAction func actionPrevious() {
        if session.isReachable{
        
            let datatoaphone: [String:Any] = ["previous" : "previous"]
            session.sendMessage(datatoaphone, replyHandler: nil, errorHandler: nil)
        }
    }
    

    @IBAction func actionPlay() {
        if session.isReachable{
        
            let datatoaphone: [String:Any] = ["isPaused" : !isPaused]
            session.sendMessage(datatoaphone, replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func actionNext() {
        
        
        if session.isReachable{
        
            let datatoaphone: [String:Any] = ["nextPlay" : "nextPlay"]
            session.sendMessage(datatoaphone, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension InterfaceController: WCSessionDelegate {
    
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let isPaused = message["isPaused"] as? Bool {
                
                self.isPaused = isPaused
                self.btnPlay.setTitle(self.isPaused ? "Paused" :"Play")
//                self.btnPlay.setBackgroundImageNamed(self.isPaused ? "pause" :"play-button-arrowhead")
            }
        }
    }
    
    
    
}
