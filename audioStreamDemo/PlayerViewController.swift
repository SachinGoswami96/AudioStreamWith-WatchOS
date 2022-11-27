//
//  PlayerViewController.swift
//
//  Created by Harshal Jadhav on 27/02/17.
//  Copyright © 2017 Harshal Jadhav. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import WatchConnectivity

class PlayerViewController: UIViewController {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var seekLoadingLabel: UILabel!
    var playList: NSMutableArray = NSMutableArray()
    var timer: Timer?
    var index: Int = Int()
    var avPlayer: AVPlayer!
    var isPaused: Bool!
    var session: WCSession?
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        playList.add("https://github.com/VivekBViOS/TillS/raw/master/ringingTone.mp3")
//        playList.add("https://github.com/VivekBViOS/TillS/raw/master/playgame_bg_music.mp3")
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(AVAudioSession.Category.playback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        if #available(iOS 13.0, *) {
            setupNowPlayingInfoCenter()
        } else {
            // Fallback on earlier versions
        }
        
        setWatchSession()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        seekLoadingLabel.alpha = 0
        isPaused = false
        playButton.setImage(UIImage(named:"pause"), for: .normal)
        guard let songUrlString = playList[self.index] as? String else {return}
        guard let songUrl = URL(string:songUrlString) else{return}
        self.play(url: songUrl)
        self.setupTimer()
    }
    
    override func viewWillDisappear( _ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.avPlayer = nil
        self.timer?.invalidate()
    }
    func setWatchSession(){
        if WCSession.isSupported(){
            session = WCSession.default
            session?.delegate =  self
            session?.activate()
        }
    }
    func play(url:URL) {
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
        self.avPlayer.automaticallyWaitsToMinimizeStalling = false
        avPlayer!.volume = 1.0
        avPlayer.play()
    }
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
         self.togglePlayPause()
    }
    
    @available(iOS 10.0, *)
    func togglePlayPause() {
        if avPlayer.timeControlStatus == .playing  {
            playButton.setImage(UIImage(named:"play"), for: .normal)
            avPlayer.pause()
            isPaused = true
        } else {
            playButton.setImage(UIImage(named:"pause"), for: .normal)
            avPlayer.play()
            isPaused = false
        }
        if let session = self.session, session.isReachable{
        
            let datatoaphone: [String:Any] = ["isPaused" : isPaused ?? true]
            session.sendMessage(datatoaphone, replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        self.nextTrack()
    }
    
    @IBAction func prevButtonClicked(_ sender: Any) {
        self.prevTrack()
    }
    
    @IBAction func sliderValueChange(_ sender: UISlider) {
        let seconds : Int64 = Int64(sender.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        avPlayer!.seek(to: targetTime)
        if(isPaused == false){
            seekLoadingLabel.alpha = 1
        }
    }
    
    @IBAction func sliderTapped(_ sender: UILongPressGestureRecognizer) {
        if let slider = sender.view as? UISlider {
            if slider.isHighlighted { return }
            let point = sender.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * (slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: false)
            let seconds : Int64 = Int64(value)
            let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
            avPlayer!.seek(to: targetTime)
            if(isPaused == false){
                seekLoadingLabel.alpha = 1
            }
        }
    }
    // Data Pass Methods
    @IBAction func sendMessage(){
        if let session = self.session, session.isReachable{
        
            let datatoaphone: [String:Any] = ["isPaused" : isPaused!]
            session.sendMessage(datatoaphone, replyHandler: nil, errorHandler: nil)
        }
        
    }
    func setupTimer(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        timer = Timer(timeInterval: 0.001, target: self, selector: #selector(PlayerViewController.tick), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    @objc func didPlayToEnd() {
        self.nextTrack()
    }
    
    func showLoader(){
        guard let value = avPlayer.currentItem?.status.rawValue else{return}
        if(value == 0){
            self.loadingLabel.isHidden = false
        }else{
            self.loadingLabel.isHidden = true
        }
    }
    
    @objc func tick(){
        showLoader()
        if(isPaused == false){
            if(avPlayer.rate == 0){
                avPlayer.play()
                seekLoadingLabel.alpha = 1
            }else{
                seekLoadingLabel.alpha = 0
            }
        }
        if((avPlayer.currentItem?.asset.duration) != nil){
            if let _ = avPlayer.currentItem?.asset.duration{}else{return}
            if let _ = avPlayer.currentItem?.currentTime(){}else{return}
            let currentTime1 : CMTime = (avPlayer.currentItem?.asset.duration)!
            let seconds1 : Float64 = CMTimeGetSeconds(currentTime1)
            let time1 : Float = Float(seconds1)
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = time1
            let currentTime : CMTime = (self.avPlayer?.currentTime())!
            let seconds : Float64 = CMTimeGetSeconds(currentTime)
            let time : Float = Float(seconds)
            self.playerSlider.value = time
            timeLabel.text =  self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.asset.duration)!)))))
            currentTimeLabel.text = self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.currentTime())!)))))
        }else{
            playerSlider.value = 0
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = 0
            timeLabel.text = "Live stream \(self.formatTimeFromSeconds(totalSeconds: Int32(CMTimeGetSeconds((avPlayer.currentItem?.currentTime())!))))"
        }
    }
    
    
    func nextTrack(){
        if(index < playList.count-1){
            index = index + 1
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
            self.play(url: URL(string:(playList[self.index] as! String))!)
        }else{
            index = 0
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
             self.play(url: URL(string:(playList[self.index] as! String))!)
        }
    }
    
    func prevTrack(){
        if(index > 0){
            index = index - 1
            isPaused = false
            playButton.setImage(UIImage(named:"pause"), for: .normal)
             self.play(url: URL(string:(playList[self.index] as! String))!)
        }
    }
    
    func formatTimeFromSeconds(totalSeconds: Int32) -> String {
        let seconds: Int32 = totalSeconds%60
        let minutes: Int32 = (totalSeconds/60)%60
        let hours: Int32 = totalSeconds/3600
        return String(format: "%02d:%02d:%02d", hours,minutes,seconds)
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            self.avPlayer = nil
            self.timer?.invalidate()
        }
    }
    
    
    @available(iOS 13.0, *)
    func setupNowPlayingInfoCenter() {
            UIApplication.shared.endReceivingRemoteControlEvents()
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
        
        
        
         let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
         var nowPlayingInfo = [String: Any]()
         let image = UIImage(named: "musicLogo") ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (_) -> UIImage in
        return image
        })
        nowPlayingInfo[MPMediaItemPropertyTitle] = "RINGTONE"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = " ARIJIT SING"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
         
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        
            let commandCenter = MPRemoteCommandCenter.shared()
            
            //Play button handler
            commandCenter.playCommand.isEnabled = true
            commandCenter.playCommand.addTarget { [weak self] event in
                print("play from carplay : \(event)")
                guard let _ = self else { return .commandFailed}
                if #available(iOS 13.0, *) {
                    MPNowPlayingInfoCenter.default().playbackState = .playing
                } else {
                    // Fallback on earlier versions
                }
                self?.avPlayer.play()
                self?.togglePlayPause()
                //MPMusicPlayerController.applicationQueuePlayer.play()
                MPMusicPlayerController.applicationMusicPlayer.play()
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self?.avPlayer.currentTime() ?? CMTime.zero)
                return .success
            }
            
            //Pause button handler
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.pauseCommand.addTarget { [weak self] event in
                print("pause from carplay : \(event)")
                guard let _ = self else { return .commandFailed}
                MPNowPlayingInfoCenter.default().playbackState = .paused
                self?.avPlayer.pause()
                self?.togglePlayPause()
                MPMusicPlayerController.applicationQueuePlayer.pause()
//                MPMusicPlayerController.applicationMusicPlayer.stop()
                return .success
            }
            
            //Previous button handler
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget {[weak self] event in
                print("Previous from carplay : \(event)")
                guard let weakSelf = self else { return .commandFailed}
//                weakSelf.playPreviousSong()
                self?.prevTrack()
                return .success
            }
            
            //Next button handler
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget {[weak self] event in
                print("Next from carplay : \(event)")
                guard let weakSelf = self else { return .commandFailed }
//                weakSelf.playNextSong()
                self?.nextTrack()
                return .success
            }
        }
}
extension PlayerViewController: WCSessionDelegate{
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let isPaused = message["isPaused"] as? Bool {
                
              self.isPaused = isPaused
//                self.isPaused ?  self.avPlayer.pause(): self.avPlayer.play()
                self.togglePlayPause()
               
            }
            
            if let nextPlay = message["nextPlay"] as? String {
                
              
//                self.isPaused ?  self.avPlayer.pause(): self.avPlayer.play()
                self.nextTrack()
               
            }
            
            if let nextPlay = message["previous"] as? String {
                
              
//                self.isPaused ?  self.avPlayer.pause(): self.avPlayer.play()
                self.prevTrack()
               
            }
            
            
        }
    }
    
    
    
}
