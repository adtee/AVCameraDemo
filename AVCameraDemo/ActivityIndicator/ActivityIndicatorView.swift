//
//  ActivityIndicatorView.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 13/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import Foundation
import UIKit

class ActivityIndicatorView : UIView{
    
    //MARK: UI elements
    fileprivate lazy var activityIndicatorView : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = UIColor(named: "AppColorBlue")
        return view
    }()
    
    
    fileprivate lazy var labelAcitivityDescription : UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.textAlignment = .center
        return view
    }()
    
    let viewBoundingBox = UIView(frame: .zero)
    
    var activityDescription : String = "Loading"{
        didSet{
            labelAcitivityDescription.text = activityDescription
        }
    }
    
    //MARK: init
    
    init() {
        super.init(frame:.zero)
        setupInitialUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitialUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInitialUI()
    }
    
    //MARK: Setup activity Indicator
    private func setupInitialUI(){
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.viewBoundingBox.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        activityIndicatorView.stopAnimating()
        
        addSubview(viewBoundingBox)
        addSubview(activityIndicatorView)
        addSubview(labelAcitivityDescription)
        
        self.layoutSubviews()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        func setupFrames(){
                   viewBoundingBox.frame.size.width =  160.0
                   viewBoundingBox.frame.size.height = 160.0
                   viewBoundingBox.frame.origin.x = ceil((bounds.width / 2.0) - (viewBoundingBox.frame.width / 2.0))
                   viewBoundingBox.frame.origin.y = ceil((bounds.height / 2.0) - (viewBoundingBox.frame.height / 2.0))
                   
                   
                   activityIndicatorView.isHidden = false
                   activityIndicatorView.frame.origin.x = ceil((bounds.width / 2.0) - (activityIndicatorView.frame.width / 2.0))
                   activityIndicatorView.frame.origin.y = ceil((bounds.height / 2.0) - (activityIndicatorView.frame.height / 2.0))
                   
                   
                   let messageLabelSize = labelAcitivityDescription.sizeThatFits(CGSize(width: viewBoundingBox.frame.size.width - 20.0 * 2.0, height: CGFloat.greatestFiniteMagnitude))
                   labelAcitivityDescription.frame.size.width = messageLabelSize.width
                   labelAcitivityDescription.frame.size.height = messageLabelSize.height
                   labelAcitivityDescription.frame.origin.x = ceil((bounds.width / 2.0) - (labelAcitivityDescription.frame.width / 2.0))
                   labelAcitivityDescription.frame.origin.y = ceil(activityIndicatorView.frame.maxY + ((viewBoundingBox.frame.maxY - activityIndicatorView.frame.maxY) / 2.0) - (labelAcitivityDescription.frame.height / 2.0))
               }
        
        setupFrames()
        
    }

}
