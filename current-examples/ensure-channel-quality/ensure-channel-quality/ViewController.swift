//
//  ViewController.swift
//  ensure-channel-quality
//
//  Created by Dasun Nirmitha on 2023-04-07.
//

import UIKit
import AVFoundation
import AgoraRtcKit

class ViewController: UIViewController {
    // The main entry point for Video SDK
    var agoraEngine: AgoraRtcEngineKit!
    // By default, set the current user role to broadcaster to both send and receive streams.
    var userRole: AgoraClientRole = .broadcaster

    // Update with the App ID of your project generated on Agora Console.
    let appID = "<#Your app ID#>"
    // Update with the temporary token generated in Agora Console.
    var token = "<#Your temp access token#>"
    // Update with the channel name you used to generate the token in Agora Console.
    var channelName = "<#Your channel name#>"
    
    // The video feed for the local user is displayed here
    var localView: UIView!
    // The video feed for the remote user is displayed here
    var remoteView: UIView!
    // Click to join or leave a call
    var joinButton: UIButton!

    // Track if the local user is in a call
    var joined: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.joinButton.setTitle( self.joined ? "Leave" : "Join", for: .normal)
            }
        }
    }
    
    var networkStatusLabel: UILabel!
    var networkStatus: UILabel!
    
    var counter1 = 0 // Controls the frequency of messages
    var counter2 = 0 // Controls the frequency of messages
    var remoteUid: UInt = 0 // Uid of the remote user
    var highQuality = true // Quality of the remote video stream being played

    override func viewDidLoad() {
         super.viewDidLoad()
         // Do any additional setup after loading the view.
         // Initializes the video view
         initViews()
         // The following functions are used when calling Agora APIs
         initializeAgoraEngine()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        leaveChannel()
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
    }

    func joinChannel() async {
        if await !self.checkForPermissions() {
            showMessage(title: "Error", text: "Permissions were not granted")
            return
        }

        let option = AgoraRtcChannelMediaOptions()

        // Set the client role option as broadcaster or audience.
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
            setupLocalVideo()
        } else {
            option.clientRoleType = .audience
        }

        // For a video call scenario, set the channel profile as communication.
        option.channelProfile = .communication

        // Join the channel with a temp token. Pass in your token and channel name here
        let result = agoraEngine.joinChannel(
            byToken: token, channelId: channelName, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in }
        )
            // Check if joining the channel was successful and set joined Bool accordingly
        if result == 0 {
            joined = true
            showMessage(title: "Success", text: "Successfully joined the channel as \(self.userRole)")
        }
    }

    func leaveChannel() {
        agoraEngine.stopPreview()
        let result = agoraEngine.leaveChannel(nil)
        // Check if leaving the channel was successful and set joined Bool accordingly
        if result == 0 { joined = false }
    }
    
    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        // Pass in your App ID here.
        config.appId = appID
        // Use AgoraRtcEngineDelegate for the following delegate parameter.
        let engineConfig = AgoraRtcEngineConfig()
        engineConfig.appId = appID
        engineConfig.audioScenario = AgoraAudioScenario.gameStreaming
        
        let logConfig = AgoraLogConfig()
        logConfig.filePath = "AppSandbox/Library/caches/agorasdk1.log" // Default path AppSandbox/Library/caches/agorasdk.log
        logConfig.fileSizeInKB = 256 // Range 128-1024 Kb
        logConfig.level = .warn
        config.logConfig = logConfig
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: engineConfig, delegate: self)
        
        // Enable the dual stream mode
        agoraEngine.enableDualStreamMode(true)
        // Set audio profile
        agoraEngine.setAudioProfile(AgoraAudioProfile.default)
        // Set the video profile
        let videoConfig = AgoraVideoEncoderConfiguration()
        // Set Mirror mode
        videoConfig.mirrorMode = AgoraVideoMirrorMode.auto
        // Set Framerate
        videoConfig.frameRate = AgoraVideoFrameRate.fps10
        // Set Bitrate
        videoConfig.bitrate = AgoraVideoBitrateStandard
        // Set Dimensions
        videoConfig.dimensions = AgoraVideoDimension640x360
        // Set orientation mode
        videoConfig.orientationMode = AgoraVideoOutputOrientationMode.adaptative
        // Set degradation preference
        videoConfig.degradationPreference = AgoraDegradationPreference.balanced
        // Apply the configuration
        agoraEngine.setVideoEncoderConfiguration(videoConfig)

        // Start the probe test
        startProbeTest()
    }
    
    func setupLocalVideo() {
        // Enable the video module
        agoraEngine.enableVideo()
        // Start the local video preview
        agoraEngine.startPreview()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        // Set the local video view
        agoraEngine.setupLocalVideo(videoCanvas)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        remoteView.frame = CGRect(x: 20, y: 50, width: 350, height: 330)
        localView.frame = CGRect(x: 20, y: 400, width: 350, height: 330)
    }

    func initViews() {
        // Initializes the remote video view. This view displays video when a remote host joins the channel.
        remoteView = UIView()
        self.view.addSubview(remoteView)
        // Initializes the local video window. This view displays video when the local user is a host.
        localView = UIView()
        self.view.addSubview(localView)
        //  Button to join or leave a channel
        joinButton = UIButton(type: .system)
        joinButton.frame = CGRect(x: 140, y: 700, width: 100, height: 50)
        joinButton.setTitle("Join", for: .normal)

        joinButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(joinButton)
        
        networkStatusLabel = UILabel(frame: CGRect(x: 50, y: 600, width: 150, height: 50))
        networkStatusLabel.text = "Network Status:"
        self.view.addSubview(networkStatusLabel)
        networkStatus = UILabel(frame: CGRect(x: 200, y: 600, width: 150, height: 50))
        self.view.addSubview(networkStatus)
        
        // Create a gesture recognizer (tap gesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))

        // Add the gesture recognizer to a view
        remoteView.addGestureRecognizer(tapGesture)
    }

    @objc func buttonAction(sender: UIButton!) {
        if !joined {
            sender.isEnabled = false
            Task {
                await joinChannel()
                sender.isEnabled = true
            }
        } else {
            leaveChannel()
        }
    }
    
    func checkForPermissions() async -> Bool {
        var hasPermissions = await self.avAuthorization(mediaType: .video)
        // Break out, because camera permissions have been denied or restricted.
        if !hasPermissions { return false }
        hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }

    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
    
    func updateNetworkStatus(quality: Int) {
        if (quality > 0 && quality < 3) { networkStatus.backgroundColor = UIColor.green }
        else if (quality <= 4) { networkStatus.backgroundColor = UIColor.yellow }
        else if (quality <= 6) { networkStatus.backgroundColor = UIColor.red }
        else { networkStatus.backgroundColor = UIColor.white }
    }
    
    func startProbeTest() {
        // Configure a LastmileProbeConfig instance.
        let config = AgoraLastmileProbeConfig()
        // Probe the uplink network quality.
        config.probeUplink = true
        // Probe the downlink network quality.
        config.probeDownlink = true
        // The expected uplink bitrate (bps). The value range is [100000,5000000].
        config.expectedUplinkBitrate = 100000
        // The expected downlink bitrate (bps). The value range is [100000,5000000].
        config.expectedDownlinkBitrate = 100000

        agoraEngine.startLastmileProbeTest(config);

        showMessage(title:"Probe Test", text:"Running the last mile probe test ...")
    }
    
    func setStreamQuality() {
        highQuality = !highQuality

        if (highQuality) {
            agoraEngine.setRemoteVideoStream(remoteUid, type: AgoraVideoStreamType.high)
            showMessage(title: "Stream Quality", text: "Switching to high-quality video")
        } else {
            agoraEngine.setRemoteVideoStream(remoteUid, type: AgoraVideoStreamType.low)
            showMessage(title: "Stream Quality", text: "Switching to low-quality video")
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        setStreamQuality()
    }
    
    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    // Callback called when a new host joins the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        agoraEngine.setupRemoteVideo(videoCanvas)
        
        remoteUid = uid
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileQuality quality: AgoraNetworkQuality) {
        self.updateNetworkStatus(quality: Int(quality.rawValue))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileProbeTest result: AgoraLastmileProbeResult) {
        agoraEngine.stopLastmileProbeTest()
        // The result object contains the detailed test results that help you
        // manage call quality. For example, the downlink jitter"
        showMessage(title: "Downlink jitter", text: String(result.downlinkReport.jitter))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        // Use DownLink NetQuality to update the network status
        self.updateNetworkStatus(quality: Int(rxQuality.rawValue))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats: AgoraChannelStats) {
        counter1 += 1
        var msg = ""

        if (counter1 == 5) {
            msg = "\(String(reportRtcStats.userCount)) user(s)"
        } else if (counter1 == 10 ) {
            msg = "Packet loss rate: \(String(reportRtcStats.rxPacketLossRate))"
            counter1 = 0
        }

        if (msg.count > 0) { showMessage(title: "Video SDK Stats", text: msg) }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid: UInt, state: AgoraVideoRemoteState,
                reason: AgoraVideoRemoteReason, elapsed: Int) {
        let stateChangeReport = ["Uid = \(remoteVideoStateChangedOfUid)", "NewState = \(state):", "Reason = \(reason):",
                                "Elapsed = \(elapsed)"].joined(separator: "\n")

        showMessage(title: "Remote video state changed:", text: stateChangeReport, delay: 8)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStats: AgoraRtcLocalVideoStats, sourceType: AgoraVideoSourceType) {
        counter2 += 1

        if (counter2 == 5) {
            let localVideoStatsReport = ["SentBitrate = \(localVideoStats.sentBitrate)", "codecType = \(localVideoStats.codecType)"].joined(separator: "\n")
            counter2 = 0;
            showMessage(title: "Local Video Stats:", text: localVideoStatsReport)
        }
    }
}


