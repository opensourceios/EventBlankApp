//
//  UIImage+Extension.swift
//  EventBlank
//
//  Created by Marin Todorov on 9/10/15.
//  Copyright (c) 2015 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

enum UIImageResizeMode {
    case Fill(CGFloat, CGFloat)
    case FillSize(CGSize)
    case Fit(CGFloat, CGFloat)
    case Match(CGFloat, CGFloat)
}

extension UIImage {
    
    func rx_resizedImage(newSizeMode: UIImageResizeMode, cornerRadius: CGFloat = 0.0) -> Observable<UIImage?> {
        return Observable.create({[weak self] observer -> Disposable in
            
            self?.asyncToSize(newSizeMode, cornerRadius: cornerRadius) { image in
                observer.onNext(image)
                observer.onCompleted()
            }
            
            return NopDisposable.instance
        })
    }
    
    func asyncToSize(newSizeMode: UIImageResizeMode, cornerRadius: CGFloat = 0.0, completion: ((UIImage?)->Void)? = nil) {

        var result: UIImage? = nil
        
        backgroundQueue({

            var newSize: CGSize!
            
            switch newSizeMode {
            case .Fill(let w, let h):
                newSize = CGSize(width: w, height: h)
            case .FillSize(let s):
                newSize = s
            case .Fit(let w, let h):
                newSize = CGSize(width: w, height: h)
            case .Match(let w, let h):
                newSize = CGSize(width: w, height: h)
            }
            
            let aspectWidth = newSize.width / self.size.width
            let aspectHeight = newSize.height / self.size.height
            let aspectRatio: CGFloat!
            
            switch newSizeMode {
            case .Fill(_, _): fallthrough
            case .FillSize(_):
                aspectRatio = max(aspectWidth, aspectHeight)
            case .Fit(_, _):
                aspectRatio = min(aspectWidth, aspectHeight)
            case .Match(_, _):
                aspectRatio = newSize.width / newSize.height
            }
            
            var rect = CGRect.zero
            
            rect.size.width = self.size.width * aspectRatio
            rect.size.height = self.size.height * aspectRatio
            rect.origin.x = (newSize.width - rect.size.width) / 2.0
            rect.origin.y = (newSize.height - rect.size.height) / 2.0

            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            if cornerRadius > 0.0 {
                let clipRect = CGRect(origin: CGPoint.zero, size: newSize)
                CGContextAddPath(UIGraphicsGetCurrentContext(), UIBezierPath(roundedRect: clipRect, cornerRadius: cornerRadius).CGPath)
                CGContextClip(UIGraphicsGetCurrentContext())
            }
            self.drawInRect(rect)
            
            result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }, completion: {
            completion?(result)
        })
    }
}