//
//  RemoteCommandManager.swift
//  audioDemoStreamfor Watch WatchKit Extension
//
//  Created by Sachingiri Goswami on 23/11/22.
//  Copyright © 2022 Harshal Jadhav. All rights reserved.
//

import Foundation
import MediaPlayer

@objc class RemoteCommandManager: NSObject {
// Reference of `MPRemoteCommandCenter` used to configure and
// setup remote control events in the application.
fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
 
    
// Example providing a MediaRemote command
func enableSkipForwardCommand(interval: Int = 15) {
    remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
    remoteCommandCenter.skipForwardCommand.addTarget(self, action:
                                                        #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
    remoteCommandCenter.skipForwardCommand.isEnabled = true
}
    
    @objc func handleSkipForwardCommandEvent(event: Any){
        print("Handle Events")
    }
}
