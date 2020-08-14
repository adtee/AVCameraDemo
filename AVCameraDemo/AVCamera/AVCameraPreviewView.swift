//
//  AVCameraPreviewView.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 13/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/// A function to specifty the Preview Layer's videoGravity. Indicates how the video is displayed within a player layer’s bounds rect.
public enum AVCameraVideoRecordingGravity {
    case resize //AVLayerVideoGravityResize
    case resizeAspect //AVLayerVideoGravityResizeAspect
    case resizeAspectFill //AVLayerVideoGravityResizeAspectFill
}

/// Class for AVCamera preview.
class AVCameraPreviewView: UIView {
    
    private var videoGravity: AVCameraVideoRecordingGravity = .resizeAspect
    
    init(frame: CGRect,  videoGravity: AVCameraVideoRecordingGravity) {
        self.videoGravity = videoGravity
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    ///Videopreview layer- will show the current time capture
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            let previewlayer = layer as! AVCaptureVideoPreviewLayer
            switch videoGravity {
            case .resize:
                previewlayer.videoGravity = AVLayerVideoGravity.resize
            case .resizeAspect:
                previewlayer.videoGravity = AVLayerVideoGravity.resizeAspect
            case .resizeAspectFill:
                previewlayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            }
            return previewlayer
    }
    
    ///Capture session to assign to layer to show live capture
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
