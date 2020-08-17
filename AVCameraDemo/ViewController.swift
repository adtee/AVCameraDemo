//
//  ViewController.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 13/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {

    
    //MARK: Outlates
    
    @IBOutlet weak var labelTimeDuration: UILabel!{
        didSet{
            imageViewRecording.isHidden = labelTimeDuration.text == "00:00"
        }
    }
    @IBOutlet weak var imageViewRecording: UIImageView!
    @IBOutlet weak var viewCamera: AVcameraView!
    
    @IBOutlet weak var buttonFlash: UIButton!
    @IBOutlet weak var buttonCameraSelection: UIButton!
    
    
    //MARK: Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup initial camera
        setupCamera()
        
    }

    //MARK: Actions
    
    @IBAction func flashButtonAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        viewCamera.flashEnabled.toggle()
    }
    
    @IBAction func videoRecordButtonAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        self.animateRecordingImage(should: sender.isSelected)
        DispatchQueue.main.async {
            if sender.isSelected{
                self.viewCamera.startVideoRecording()
            }else{
                self.viewCamera.stopVideoRecording()
            }
        }
       
    }
    
    @IBAction func cameraSelectionAction(_ sender: UIButton) {
        viewCamera.switchCamera()
    }
    
    
    //MARK: Recording image animation
    ///animate recording image while video is capturing
    func animateRecordingImage(should animate : Bool){
        if animate{
            var animationOption : UIView.AnimationOptions = [.curveEaseInOut]
            imageViewRecording.animateViewInScaleEffect(should: true, duration: 0.8, delay: 0, scalex: 1.5, scaleY: 1.5, animationOptions: &animationOption )
        }else{
            self.imageViewRecording.transform = .identity
            self.imageViewRecording.layer.removeAllAnimations()
        }
    }
}


//MARK:AVCamera functions
extension ViewController : AVcameraViewDelegate{
    
    //MARK: AVCamera setup
    ///setup AVCameraview properties
    func setupCamera(){
        viewCamera.cameraDelegate = self
        viewCamera.shouldUseDeviceOrientation = true
    }
    
    //MARK: AVCamera Delegate
    
    func AVcameraView(didBeginRecordingVideo camera: AVcameraView.CameraSelection) {
        print("Did Begin Recording")
        DispatchQueue.main.async {
            self.imageViewRecording.isHidden = false
            
            UIView.animate(withDuration: 0.25, animations: {
                self.buttonFlash.alpha = 0.0
                self.buttonCameraSelection.alpha = 0.0
            })
        }
    }
    
    func AVcameraView(recorded timeString: String) {
        DispatchQueue.main.async {
            self.labelTimeDuration.text = timeString
        }
    }
    
    func AVcameraView(didFinishRecordingVideo camera: AVcameraView.CameraSelection) {
        print("Did finish Recording")
        DispatchQueue.main.async {
            self.showActivityIndicatior(withMessage: "Processing Video")
            self.imageViewRecording.isHidden = true
            UIView.animate(withDuration: 0.25, animations: {
                self.buttonFlash.alpha = 1.0
                self.buttonCameraSelection.alpha = 1.0
            })
        }
    }

    func AVcameraView( didFinishProcessVideoAt url: URL) {
        //save video to lib

        func handleViewSaveAction(savedSuccessfully : Bool){
            self.hideActivityIndicator()
            self.labelTimeDuration.text = "00:00"
            self.imageViewRecording.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                self.showOkAlert(withTitle: "AVCameraDemo", message: savedSuccessfully ? "Succesfully created video and saved in your photo library." : "Failed to create video.please try again.")
            }
        }
    
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            DispatchQueue.main.async {
                handleViewSaveAction(savedSuccessfully: saved)
            }
        }
       
    }

    func AVcameraView(didFailToRecordVideo error: Error) {
        print(error)
        self.showOkAlert(withTitle: "AVCameraDemo", message: error.localizedDescription)
    }
    
    func AVcameraView(didErrorOccured message: String) {
        self.showOkAlert(withTitle: "AVCameraDemo", message: message)
    }
    
}
