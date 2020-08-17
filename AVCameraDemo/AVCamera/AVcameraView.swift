//
//  AVcameraView.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 13/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import Foundation
import AVKit
import UIKit

///Delegate for AVCameraView
public protocol AVcameraViewDelegate: class {
    
    func AVcameraView(didBeginRecordingVideo camera: AVcameraView.CameraSelection)
    
    func AVcameraView(didFinishRecordingVideo camera: AVcameraView.CameraSelection)
    
    func AVcameraView(didFinishProcessVideoAt url: URL)
    
    func AVcameraView(didFailToRecordVideo error: Error)
    
    func AVcameraView(didSwitchCameras camera: AVcameraView.CameraSelection)
    
    func AVcameraView(recorded timeString: String)
    
    func AVcameraView(didErrorOccured message : String)
}

//Delegate methods optional
public extension AVcameraViewDelegate {
    
    func AVcameraView(didBeginRecordingVideo camera: AVcameraView.CameraSelection){}
    
    func AVcameraView(didFinishRecordingVideo camera: AVcameraView.CameraSelection){}
    
    func AVcameraView(didFinishProcessVideoAt url: URL){}
    
    func AVcameraView(didFailToRecordVideo error: Error){}
    
    func AVcameraView(didSwitchCameras camera: AVcameraView.CameraSelection){}
    
    func AVcameraView(recorded timeString: String){}
    
    func AVcameraView(didErrorOccured message : String){}
}

//--------------------------------------------------------------------------------------------------------------

open class AVcameraView: UIView {
    
    // MARK: Enumeration Declaration
    
    ///for Camera Selection
    
    public enum CameraSelection {
        case rear
        case front
    }
    
    ///for video quality of the capture session. Corresponds to a AVCaptureSessionPreset
    
    
    public enum VideoQuality {
        
        /// AVCaptureSessionPresetHigh
        case high
        
        /// AVCaptureSessionPresetMedium
        case medium
        
        /// AVCaptureSessionPresetLow
        case low
        
        /// AVCaptureSessionPreset352x288
        case resolution352x288
        
        /// AVCaptureSessionPreset640x480
        case resolution640x480
        
        /// AVCaptureSessionPreset1280x720
        case resolution1280x720
        
        /// AVCaptureSessionPreset1920x1080
        case resolution1920x1080
        
        /// AVCaptureSessionPreset3840x2160
        case resolution3840x2160
        
        /// AVCaptureSessionPresetiFrame960x540
        case iframe960x540
        
        /// AVCaptureSessionPresetiFrame1280x720
        case iframe1280x720
    }
    
    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    // MARK: Variable Declarations
    
    public weak var cameraDelegate : AVcameraViewDelegate?
        
    public var videoQuality : VideoQuality = .high
    
    public var flashEnabled = false
    
    public var allowBackgroundAudio = true
    
    public var doubleTapCameraSwitch = true
    
    public var defaultCamera = CameraSelection.rear
    
    public var shouldUseDeviceOrientation = false
    
    
    //MARK: Observation variable
    private(set) public var isVideoRecording = false
    
    private(set) public var isSessionRunning = false
    
    private(set) public var currentCamera = CameraSelection.rear
    
    
    // MARK: Constant Declarations
    
    public let session = AVCaptureSession()
    
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [])
    
    // MARK:  Variable Declarations
    
    fileprivate var isCameraTorchOn = false
    
    fileprivate var setupResult = SessionSetupResult.success
    
    fileprivate var backgroundRecordingID : UIBackgroundTaskIdentifier? = nil
    
    fileprivate var videoDeviceInput : AVCaptureDeviceInput!
    
    fileprivate var movieFileOutput : AVCaptureMovieFileOutput?
    
    fileprivate var videoDevice : AVCaptureDevice?
    
    fileprivate var previewLayer : AVCameraPreviewView!
    
    fileprivate var deviceOrientation : UIDeviceOrientation?
        
    fileprivate var timer : Timer!
    
    // MARK: Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitialValues()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInitialValues()
    }
    
    
    private func setupInitialValues(){
        
        ///Check status of Camera and microphone usage authorisation
        func checkVideoCaptureAuthorisation(){
            // Test authorization status for Camera and Micophone
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video){
            case .authorized:
                // already authorized
                break
            case .notDetermined:
                
                // not yet determined
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [unowned self] granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
            default:
                
                // already been asked. Denied access
                setupResult = .notAuthorized
            }
            sessionQueue.async { [unowned self] in
                self.configureSession()
            }
        }
        
        func validateAuthorisationResult(){
            sessionQueue.async {
                switch self.setupResult {
                case .success:
                   
                    DispatchQueue.main.async {
                        // Begin Session
                        self.session.startRunning()
                        self.isSessionRunning = self.session.isRunning
                        // Preview layer video orientation can be set only after the connection is created
                        self.previewLayer.videoPreviewLayer.connection?.videoOrientation = self.getPreviewLayerOrientation()
                    }
                case .notAuthorized:
                    // Prompt to App Settings
                    self.promptToAppSettings()
                case .configurationFailed:
                    // Unknown Error
                    DispatchQueue.main.async(execute: {
                        self.cameraDelegate?.AVcameraView(didErrorOccured: "Unable to capture video")
                    })
                }
            }
        }
        
        
        //Add preview layer
        DispatchQueue.main.async {
            self.previewLayer = AVCameraPreviewView(frame: self.bounds, videoGravity: .resizeAspectFill)
            self.addSubview(self.previewLayer)
            self.sendSubviewToBack(self.previewLayer)
            
            // Add Gesture Recognizers
            self.addGestureRecognizers()
            
            //Assign previewLayer
            self.previewLayer.session = self.session
            
            //check authorisation
            checkVideoCaptureAuthorisation()
            
        }
        
       
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            // Subscribe to device rotation notifications
            
            if self.shouldUseDeviceOrientation {
                self.subscribeToDeviceOrientationChangeNotifications()
            }
            
            // Set background audio preference
            self.setBackgroundAudioPreference()
            
            //Check authorisation result
            validateAuthorisationResult()
        }
        
    }
    
    
    // MARK: ViewDidLayoutSubviews
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        DispatchQueue.main.async {
            layer.videoOrientation = orientation
            self.previewLayer.frame = self.frame
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        ///Setup preview layer layout as per the orientation
        func setupPreviewLayerOrientation(){
            
            if let connection =  self.previewLayer?.videoPreviewLayer.connection  {
                
                let currentDevice: UIDevice = UIDevice.current
                
                let orientation: UIDeviceOrientation = currentDevice.orientation
                
                let previewLayerConnection : AVCaptureConnection = connection
                
                if previewLayerConnection.isVideoOrientationSupported {
                    
                    switch (orientation) {
                    case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    }
                }
            }
        }
        
        setupPreviewLayerOrientation()
       
        
    }
    
    deinit {
        // If session is running, stop the session
        if self.isSessionRunning == true {
            self.session.stopRunning()
            self.isSessionRunning = false
        }
        
        //Disble flash if it is currently enabled
        disableFlash()
        
        // Unsubscribe from device rotation notifications
        if shouldUseDeviceOrientation {
            unsubscribeFromDeviceOrientationChangeNotifications()
        }
    }
    
    
    
    // MARK: Video Capture user interactive Functions
    
    ///Start recording video session
    public func startVideoRecording() {
        
        guard self.session.isRunning == true else {
            return
        }
        
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        
        if currentCamera == .rear && flashEnabled == true {
            enableFlash()
        }
        
        sessionQueue.async { [unowned self] in
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = self.movieFileOutput?.connection(with: AVMediaType.video)
                
                
                //flip video output if front facing camera is selected
                if self.currentCamera == .front {
                    movieFileOutputConnection?.isVideoMirrored = true
                }
                
                movieFileOutputConnection?.videoOrientation = self.getVideoOrientation()
                
                // Start recording to a temporary file.
                let outputFileName = UUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
                self.isVideoRecording = true

                DispatchQueue.main.async {
                    self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                    self.cameraDelegate?.AVcameraView(didBeginRecordingVideo: self.currentCamera)
                }
                
            }
            else {
                movieFileOutput.stopRecording()
            }
        }
    }
    
    ///Monitor the time and update video capture time
    @objc func updateTime(){
        
        let currenTime = CMTimeGetSeconds((self.movieFileOutput?.recordedDuration) ?? CMTime.zero)
        let timeString = String.init().appendingFormat("%.2d:%.2d",Int(currenTime/60),Int(currenTime.truncatingRemainder(dividingBy: 60)))
        print("current time \(currenTime) & Display text is \(timeString)")
        DispatchQueue.main.async {
            self.cameraDelegate?.AVcameraView(recorded:timeString)
        }
    }
    
    
    ///Stop recording video capturing
    public func stopVideoRecording() {
        sessionQueue.async {
            if self.movieFileOutput?.isRecording == true {
                self.isVideoRecording = false
                self.movieFileOutput!.stopRecording()
                self.disableFlash()
                DispatchQueue.main.async {
                    self.timer.invalidate()
                    self.cameraDelegate?.AVcameraView(didFinishRecordingVideo: self.currentCamera)
                }
            }
        }
    }
    
    
    //MARK: Camera option Functions
    
    ///Switch camrea between front and rare
    public func switchCamera() {
        guard isVideoRecording != true else {
            //TODO: Look into switching camera during video recording
            print("ERROR: Switching between cameras while recording video is not supported")
            return
        }
        
        guard session.isRunning == true else {
            return
        }
        
        switch currentCamera {
        case .front:
            currentCamera = .rear
        case .rear:
            currentCamera = .front
            
        }
        
        session.stopRunning()
        
        sessionQueue.async { [unowned self] in
            
            // remove and re-add inputs and outputs
            
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            
            self.addInputs()
            DispatchQueue.main.async {
                self.cameraDelegate?.AVcameraView(didSwitchCameras: self.currentCamera)
            }
            
            self.session.startRunning()
        }
    }
    
    // MARK: Video Capture Functions
    
    /// Configure session
    
    fileprivate func configureSession() {
        guard setupResult == .success else {
            return
        }
        // Set default camera
        
        currentCamera = defaultCamera
        
        // begin configuring session
        
        session.beginConfiguration()
        configureVideoPreset()
        addVideoInput()
        addAudioInput()
        configureVideoOutput()
        session.commitConfiguration()
    }
    
    /// Add inputs after changing camera()
    
    fileprivate func addInputs() {
        session.beginConfiguration()
        configureVideoPreset()
        addVideoInput()
        addAudioInput()
        session.commitConfiguration()
    }
    
    /// Configure image quality preset
    
    fileprivate func configureVideoPreset() {
        if currentCamera == .front {
            session.sessionPreset = AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: .high))
        } else {
            if session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: videoQuality))) {
                session.sessionPreset = AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: videoQuality))
            } else {
                session.sessionPreset = AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: .high))
            }
        }
    }
    
    /// Add Video Inputs
    
    fileprivate func addVideoInput() {
        switch currentCamera {
        case .front:
            videoDevice = AVcameraView.deviceWithMediaType(.video, preferringPosition: .front)
        case .rear:
            videoDevice = AVcameraView.deviceWithMediaType(.video, preferringPosition: .back)
        }
        
        if let device = videoDevice {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = true
                    }
                }
                
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                
                device.unlockForConfiguration()
            } catch {
                print("ERROR: Error locking configuration")
            }
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("ERROR: Could not add video device input to the session")
                print(session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: videoQuality))))
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("ERROR: Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }
    }
    
    /// Add Audio Inputs
    
    fileprivate func addAudioInput() {
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            }
            else {
                print("ERROR: Could not add audio device input to the session")
            }
        }
        catch {
            print("ERROR: Could not create audio device input: \(error)")
        }
    }
    
    /// Configure Movie Output
    
    fileprivate func configureVideoOutput() {
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(with: AVMediaType.video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        }
    }
    
    
    /// Orientation management
    
    fileprivate func subscribeToDeviceOrientationChangeNotifications() {
        self.deviceOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    fileprivate func unsubscribeFromDeviceOrientationChangeNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        self.deviceOrientation = nil
    }
    
    @objc fileprivate func deviceDidRotate() {
        if !UIDevice.current.orientation.isFlat {
            self.deviceOrientation = UIDevice.current.orientation
        }
    }
    
    fileprivate func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        // Depends on layout orientation, not device orientation
        switch UIDevice.current.orientation {
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .faceUp:
            return AVCaptureVideoOrientation.portrait
        case .faceDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        @unknown default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    fileprivate func getVideoOrientation() -> AVCaptureVideoOrientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else {
           
            return self.previewLayer!.videoPreviewLayer.connection!.videoOrientation
           
        }
        
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return .portrait
        }
    }
    
    fileprivate func getImageOrientation(forCamera: CameraSelection) -> UIImage.Orientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return forCamera == .rear ? .right : .leftMirrored }
        
        switch deviceOrientation {
        case .landscapeLeft:
            return forCamera == .rear ? .up : .downMirrored
        case .landscapeRight:
            return forCamera == .rear ? .down : .upMirrored
        case .portraitUpsideDown:
            return forCamera == .rear ? .left : .rightMirrored
        default:
            return forCamera == .rear ? .right : .leftMirrored
        }
    }
    
    
    
    /// Handle Denied App Privacy Settings
    
    fileprivate func promptToAppSettings() {
        // prompt User with UIAlertView
        
        DispatchQueue.main.async(execute: {
            self.cameraDelegate?.AVcameraView(didErrorOccured: "App doesn't have permission to use the camera, please change privacy settings")
        })
    }
    
    fileprivate func videoInputPresetFromVideoQuality(quality: VideoQuality) -> String {
        switch quality {
        case .high: return AVCaptureSession.Preset.high.rawValue
        case .medium: return AVCaptureSession.Preset.medium.rawValue
        case .low: return AVCaptureSession.Preset.low.rawValue
        case .resolution352x288: return AVCaptureSession.Preset.cif352x288.rawValue
        case .resolution640x480: return AVCaptureSession.Preset.vga640x480.rawValue
        case .resolution1280x720: return AVCaptureSession.Preset.iFrame1280x720.rawValue
        case .resolution1920x1080: return AVCaptureSession.Preset.hd1920x1080.rawValue
        case .iframe960x540: return AVCaptureSession.Preset.iFrame960x540.rawValue
        case .iframe1280x720: return AVCaptureSession.Preset.iFrame1280x720.rawValue
        case .resolution3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSession.Preset.hd4K3840x2160.rawValue
            }
            else {
                print("[SwiftyCam]: Resolution 3840x2160 not supported")
                return AVCaptureSession.Preset.high.rawValue
            }
        }
    }
    
    /// Get Devices
    
    fileprivate class func deviceWithMediaType(_ mediaType: AVMediaType, preferringPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [ .builtInWideAngleCamera, .builtInDualCamera ],
            mediaType: mediaType,
            position: position
        )
        let devices = deviceDiscoverySession.devices
        
        return devices.filter({ $0.position == position }).first
    }
    
    /// Enable or disable flash for photo
    
    fileprivate func changeFlashSettings(device: AVCaptureDevice, mode: AVCaptureDevice.TorchMode) {
        do {
            try device.lockForConfiguration()
            device.torchMode = mode
            device.unlockForConfiguration()
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    /// Enable flash
    
    fileprivate func enableFlash() {
        if self.isCameraTorchOn == false {
            toggleFlash()
        }
    }
    
    /// Disable flash
    
    fileprivate func disableFlash() {
        if self.isCameraTorchOn == true {
            toggleFlash()
        }
    }
    
    /// Toggles between enabling and disabling flash
    
    fileprivate func toggleFlash() {
        guard self.currentCamera == .rear else {
            // Flash is not supported for front facing camera
            return
        }
        
        let device = AVCaptureDevice.default(for: .video)
        
        // Check if device has a flash
        if (device?.hasTorch)! {
            do {
                try device?.lockForConfiguration()
                if (device?.torchMode == AVCaptureDevice.TorchMode.on) {
                    device?.torchMode = AVCaptureDevice.TorchMode.off
                    self.isCameraTorchOn = false
                } else {
                    do {
                        try device?.setTorchModeOn(level: 1.0)
                        self.isCameraTorchOn = true
                    } catch {
                        print("ERROR: \(error)")
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print("ERROR: \(error)")
            }
        }
    }
    
    /// Sets whether SwiftyCam should enable background audio from other applications or sources
    
    fileprivate func setBackgroundAudioPreference() {
        guard allowBackgroundAudio == true else {
            return
        }
        do{
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: [.duckOthers, .defaultToSpeaker])
            
            session.automaticallyConfiguresApplicationAudioSession = false
        }
        catch {
            print("ERROR: Failed to set background audio preference")
            
        }
    }
}

// MARK: AVCaptureFileOutputRecordingDelegate

extension AVcameraView : AVCaptureFileOutputRecordingDelegate {
    
     /// Process newly captured video and write it to temporary directory
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if UIDevice.current.isMultitaskingSupported && self.backgroundRecordingID != nil{
            UIApplication.shared.endBackgroundTask(self.backgroundRecordingID!)
            self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
        }
        
        if error != nil, let videoRecordingError = error{
            DispatchQueue.main.async {
                self.cameraDelegate?.AVcameraView(didFailToRecordVideo: videoRecordingError)
            }
            return
        }
        
        
        //Call delegate function with the URL of the outputfile
        DispatchQueue.main.async {
            self.cameraDelegate?.AVcameraView(didFinishProcessVideoAt: outputFileURL)
        }
        
    }
  
}

// Mark: UIGestureRecognizer Declarations

extension AVcameraView {
    
    /// Handle double tap gesture
    
    @objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
        guard doubleTapCameraSwitch == true else {
            return
        }
        switchCamera()
    }
    
    
    fileprivate func addGestureRecognizers() {
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        previewLayer.addGestureRecognizer(doubleTapGesture)
        
    }
}




