//
//  CodeReaderOverlayView.swift
//  CodeReader
//
//  Created by Evgene Podkorytov on 17.07.2018.
//  Copyright © 2018 Podkorytov iEvgen. All rights reserved.
//

import UIKit

public final class CodeReaderOverlayView: UIView {
    private var overlay: CAShapeLayer = {
        var overlay             = CAShapeLayer()
        overlay.backgroundColor = UIColor.clear.cgColor
        overlay.fillColor       = UIColor.clear.cgColor
        overlay.strokeColor     = UIColor.white.cgColor
        overlay.lineWidth       = 1
        return overlay
    }()
    
    private var backgroundOverlay: CAShapeLayer = {
        var overlay             = CAShapeLayer()
        overlay.backgroundColor = UIColor.clear.cgColor
        overlay.fillColor       = UIColor.clear.cgColor
        overlay.strokeColor     = UIColor.clear.cgColor
        return overlay
    }()
    
    public var captureFrame: CGRect {
        var innerRect = self.frame.insetBy(dx: 50, dy: 50)
        let minSize   = min(innerRect.width, innerRect.height)
        
        if innerRect.width != minSize {
            innerRect.origin.x   += (innerRect.width - minSize) / 2
            innerRect.size.width = minSize
        }
        else if innerRect.height != minSize {
            innerRect.origin.y    += (innerRect.height - minSize) / 2
            innerRect.size.height = minSize
        }
        return innerRect
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupOverlay()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupOverlay()
    }
    
    private func setupOverlay() {
        layer.addSublayer(backgroundOverlay)
        layer.addSublayer(overlay)
    }
    
    var overlayColor: UIColor = UIColor.white {
        didSet {
            self.overlay.strokeColor = overlayColor.cgColor
            
            self.setNeedsDisplay()
        }
    }
    
    var overlayBackgroundColor: UIColor = UIColor.clear {
        didSet {
            self.backgroundOverlay.fillColor = overlayBackgroundColor.cgColor
            
            self.setNeedsDisplay()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        let overlayPath = UIBezierPath(roundedRect: captureFrame, cornerRadius: 5)
        overlay.path = overlayPath.cgPath
        
        let bgPath = UIBezierPath(rect: frame)
        bgPath.append(overlayPath.reversing())
        
        backgroundOverlay.path = bgPath.cgPath
    }
}
