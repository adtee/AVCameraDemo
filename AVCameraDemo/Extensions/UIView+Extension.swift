//
//  UIView+Extension.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 16/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    ///Animate view in scale effect - in disired scale size, repeate animation , with the duration, and animation options
    func animateViewInScaleEffect(should repeate: Bool,duration: Double = 0.8,delay: Double = 0,scalex : CGFloat, scaleY: CGFloat,animationOptions : inout UIView.AnimationOptions){
        
        if repeate{
            animationOptions.insert(.repeat)
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: animationOptions, animations: {
            self.transform = CGAffineTransform(scaleX: scalex, y: scaleY)
        }) { (success) in
            if repeate{
                self.transform = .identity
            }
        }
    }
    
}
