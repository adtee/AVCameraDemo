//
//  UIViewcontroller+Extension.swift
//  AVCameraDemo
//
//  Created by Aditi Pancholi on 13/08/20.
//  Copyright © 2020 Aditi Mehta. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    ///show processing indicator view with the message
    func showActivityIndicatior(withMessage: String){
        DispatchQueue.main.async {
            let view = ActivityIndicatorView(frame: self.view.frame)
                   view.activityDescription = withMessage
                   view.tag = 007
                   view.alpha = 0
                   view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                   self.view.addSubview(view)
                   UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                       view.transform = .identity
                       view.alpha = 1
                   }, completion: nil)
        }
    }
    
    ///hide presented activity indicater view
    func hideActivityIndicator(){
        DispatchQueue.main.async {
            if let view =  self.view.viewWithTag(007){
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    view.alpha = 0
                }, completion: { (success) in
                    view.removeFromSuperview()
                })
            }
        }
    }
    
    ///System Alertview with title, message and ok action
    func showOkAlert(withTitle: String, message: String){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: withTitle, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}
