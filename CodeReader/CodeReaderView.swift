//
//  CodeReaderView.swift
//  CodeReader
//
//  Created by Evgene Podkorytov on 19.07.2018.
//  Copyright © 2018 Podkorytov iEvgen. All rights reserved.
//

import UIKit
import AVKit
import Extensions
import ImageExtended

import Indicator

public struct CodeReaderAlertItem {
    var message: String
    var title: String
    
}
public enum CodeReaderAlertTypes {
    case indicator(Indicator)
    case accept(title: String, message: String?)
    case error(title: String, message: String?)
    case warning(title: String, message: String?)
}

public enum CodeReaderAction {
    case light
    case sound
    case custom(image: UIImage, action: (() -> Void)?)
}

public protocol CodeReaderDisplayable {
    var cameraView: UIView { get }
    
    var overlayView: CodeReaderOverlayView? { get }
    
    func setNeedsUpdateOrientation()
    func setupComponents(_ reader: CodeReader?)
}

public struct CodeReaderContainer {
    let view: UIView
    public let displayable: CodeReaderDisplayable
    
    public init<T: CodeReaderDisplayable>(displayable: T) where T: UIView {
        self.view        = displayable
        self.displayable = displayable
    }
    
    // MARK: - Convenience Methods
    
    func setupComponents(_ reader: CodeReader? = nil) {
        displayable.setupComponents(reader)
    }
}

final public class CodeReaderView: UIView, CodeReaderDisplayable {
    public var style: CodeReaderStyleProtocol = CodeReaderStyleDefault()
    
    public lazy var overlayView: CodeReaderOverlayView? = {
        let view = CodeReaderOverlayView()
            view.backgroundColor                           = .clear
            view.overlayBackgroundColor                    = style.overlayBackgroundColor
            view.clipsToBounds                             = true
            view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public let cameraView: UIView = {
        let view = UIView()
            view.clipsToBounds                             = true
            view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    //
    public var toolItemSpacing: CGFloat = 5.0 {
        didSet {
            self.toolView.spacing   = toolItemSpacing
        }
    }
    public let toolView: UIStackView = {
        let view = UIStackView()
            view.backgroundColor                           = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis  = UILayoutConstraintAxis.vertical
            view.distribution  = UIStackViewDistribution.equalSpacing
            view.alignment = UIStackViewAlignment.top
        return view
    }()
    private var toolHieght: NSLayoutConstraint
    private let toolWidght: CGFloat = 44.0
    
    //
    private lazy var btnClose: UIButton = {
        let view = UIButton()
            view.backgroundColor                           = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setImage(UIImage(named: "close", in: Bundle(for: CodeReader.self), compatibleWith: nil)?.tintPictogram(with: style.iconColor), for: .normal)
            view.action(for: .touchUpInside) {
                self.reader?.didCancel?()
            }
        return view
    }()
    
    //
    private lazy var btnToggleLight: UIButton? = {
        let view = UIButton()
            view.backgroundColor                           = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setImage(UIImage(named: "light", in: Bundle(for: CodeReader.self), compatibleWith: nil)?.tintPictogram(with: style.iconColor), for: .normal)
            view.action(for: .touchUpInside, withClosure: {
                self.light = !self.light
            })
        return view
    }()
    //
    private lazy var btnToggleSound: UIButton? = {
        let view = UIButton()
        view.backgroundColor                           = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "soundon", in: Bundle(for: CodeReader.self), compatibleWith: nil)?.tintPictogram(with: style.iconColor), for: .normal)
        view.action(for: .touchUpInside, withClosure: {
            self.sound = !self.sound
        })
        return view
    }()
    
    //
    public var light: Bool = false {
        didSet{
            self.reader?.toggleTorch(self.light)
            var image = UIImage(named: "light", in: Bundle(for: CodeReader.self), compatibleWith: nil)
            if self.light {
                image = image?.tintPictogram(with: .yellow)
            } else {
                image = image?.tintPictogram(with: self.style.iconColor)
            }
            self.btnToggleLight?.setImage(image, for: .normal)
        }
    }
    public var sound: Bool = true {
        didSet{
            let image = UIImage(named: self.sound ? "soundon" : "nosound", in: Bundle(for: CodeReader.self), compatibleWith: nil)?.tintPictogram(with: style.iconColor)
            self.btnToggleSound?.setImage(image, for: .normal)
        }
    }
    //
    
    public var buttons: Array<CodeReaderAction> = Array<CodeReaderAction>() {
        didSet {
            toolView.arrangedSubviews.forEach { button in
                toolView.removeArrangedSubview(button)
            }
            
            toolHieght.constant = CGFloat(buttons.count) * toolWidght + CGFloat(buttons.count - 1) * toolItemSpacing
            
            buttons.forEach { buttonType in
                switch buttonType {
                    case .sound:
                        toolView.addArrangedSubview(btnToggleSound!)
                        btnToggleSound?.widthAnchor.constraint(equalToConstant: toolWidght).isActive = true
                        btnToggleSound?.heightAnchor.constraint(equalToConstant: toolWidght).isActive = true
                    break
                    case .light:
                        toolView.addArrangedSubview(btnToggleLight!)
                        btnToggleLight?.widthAnchor.constraint(equalToConstant: toolWidght).isActive = true
                        btnToggleLight?.heightAnchor.constraint(equalToConstant: toolWidght).isActive = true
                    break
                    case .custom(let image, let action):
                        let button = UIButton()
                            button.backgroundColor                           = .clear
                            button.translatesAutoresizingMaskIntoConstraints = false
                            button.setImage(image.tintPictogram(with: style.iconColor), for: .normal)
                            button.action(for: .touchUpInside, withClosure: {
                                action?()
                            })
                            button.widthAnchor.constraint(equalToConstant: toolWidght).isActive = true
                            button.heightAnchor.constraint(equalToConstant: toolWidght).isActive = true
                        toolView.addArrangedSubview(button)
                    break
                }
                
            }
        }
    }
    
    private weak var reader: CodeReader?
    
    public override init(frame: CGRect) {
        toolHieght = toolView.heightAnchor.constraint(equalToConstant: 0.0)
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupComponents(_ reader: CodeReader?) {
        self.reader               = reader
        self.reader?.torchLevel = style.torchLevel
        
        addComponents()
        
        overlayView?.isHidden        = !style.showOverlay
        
        cameraView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cameraView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cameraView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        cameraView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        
        
        
        if let overlayView = overlayView {
            overlayView.topAnchor.constraint(equalTo: cameraView.topAnchor).isActive = true
            overlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
            overlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
            overlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        }
        
        //
        if let parent = btnClose.superview {
            btnClose.widthAnchor.constraint(equalToConstant: toolWidght).isActive = true
            btnClose.heightAnchor.constraint(equalToConstant: toolWidght).isActive = true
            btnClose.topAnchor.constraint(equalTo: parent.topAnchor, constant: 20.0).isActive = true
            btnClose.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 10.0).isActive = true
        }
        
        //
        if let parent = toolView.superview {
            toolView.widthAnchor.constraint(equalToConstant: toolWidght).isActive = true
            toolView.topAnchor.constraint(equalTo: parent.topAnchor, constant: 20.0).isActive = true
            toolView.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: 0.0).isActive = true
            toolHieght.isActive = true
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        reader?.previewLayer.frame = bounds
        
        if let indicator = self.indicator {
            indicator.center = cameraView.center
        }
        
        if let lbMessage = lbMessage {
            let minSize = min(self.cameraView.frame.insetBy(dx: 70, dy: 70).width, self.cameraView.frame.insetBy(dx: 70, dy: 70).height)
            lbMessage.frame.size = CGSize(width: minSize, height: minSize)
            lbMessage.center = self.cameraView.center
        }
    }
    //
    private var indicator: Indicator? = nil
    private var lbMessage: UILabel? = nil
    
    private func prepareLabel(_ title: String, message: String?, textColor: UIColor, backgroundColor: UIColor, titleFont: UIFont, messageFont: UIFont) -> UILabel {
        let titleParagraph = NSMutableParagraphStyle()
            titleParagraph.alignment = .center
        
        var attrs = [NSAttributedStringKey.font : titleFont,
                     NSAttributedStringKey.foregroundColor : textColor,
                     NSAttributedStringKey.paragraphStyle: titleParagraph] as [NSAttributedStringKey : Any]
        
        let result = NSMutableAttributedString(string: title.uppercased(), attributes: attrs)
        //
        if let message = message {
            let textParagraph = NSMutableParagraphStyle()
            textParagraph.alignment = .center
            textParagraph.paragraphSpacingBefore = 14
            
            attrs = [NSAttributedStringKey.font : messageFont,
                     NSAttributedStringKey.foregroundColor : textColor,
                     NSAttributedStringKey.paragraphStyle: textParagraph] as [NSAttributedStringKey : Any]
            
            let attributedString = NSMutableAttributedString(string: "\n\(message)", attributes:attrs)
            
            result.append(attributedString)
        }
        
        
        let label = UILabel()
            label.padding = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
            label.numberOfLines = 0
            label.layer.cornerRadius = 5.0
            label.layer.backgroundColor = backgroundColor.cgColor
            label.attributedText = result
        
        return label
    }
    
    public func showAlert(_ type: CodeReaderAlertTypes){
        reader?.stopScanning()
        
        hideAlert()
        
        switch type {
            case .indicator(let indicator):
                self.indicator = indicator
                if let indicator = self.indicator {
                    cameraView.addSubview(indicator)
                }
                
                self.indicator?.startAnimating()
                startTimerForBorderReset()
                
                
                
                break
            case .accept(let title, let message):
                self.lbMessage = prepareLabel(title, message: message, textColor: self.style.acceptTitleColor, backgroundColor: self.style.overlayAcceptBackgroundColor, titleFont: self.style.titleFont, messageFont: self.style.messageFont)
                
                if let overlayView = self.overlayView {
                    UIView.animate(withDuration: 0.15) {
                        overlayView.overlayColor = self.style.overlayAcceptFrameColor
                        //overlayView.overlayBackgroundColor = self.style.overlayAcceptBackgroundColor
                    }
                }
                break
            case .error(let title, let message):
                self.lbMessage = prepareLabel(title, message: message, textColor: self.style.errorTitleColor, backgroundColor: self.style.overlayErrorBackgroundColor, titleFont: self.style.titleFont, messageFont: self.style.messageFont)
                UIView.animate(withDuration: 0.15) {
                    if let overlayView = self.overlayView {
                        overlayView.overlayColor = self.style.overlayErrorFrameColor
                        //overlayView.overlayBackgroundColor = self.style.overlayErrorBackgroundColor
                    }
                }
                
                break
            case .warning(let title, let message):
                self.lbMessage = prepareLabel(title, message: message, textColor: self.style.warningTitleColor, backgroundColor: self.style.overlayWarningBackgroundColor, titleFont: self.style.titleFont, messageFont: self.style.messageFont)
                UIView.animate(withDuration: 0.15) {
                    if let overlayView = self.overlayView {
                        overlayView.overlayColor = self.style.overlayWarningFrameColor
                        //overlayView.overlayBackgroundColor = self.style.overlayWarningBackgroundColor
                    }
                }
                
                break
        
        }
        
        if let lbMessage = self.lbMessage {
            self.cameraView.addSubview(lbMessage)
        }
        layoutSubviews()
    }
    
    public func hideAlert(){
        if let indicator = indicator {
            indicator.stopAnimating()
            if let _ = self.indicator?.superview {
                self.indicator?.removeFromSuperview()
            }
            self.indicator = nil
        }
        
        if let label = self.lbMessage {
            if let _ = label.superview {
                label.removeFromSuperview()
            }
            self.lbMessage = nil
        }
        UIView.animate(withDuration: 0.15) {
            if let overlayView = self.overlayView {
                overlayView.overlayColor = self.style.overlayFrameColor
                overlayView.overlayBackgroundColor = self.style.overlayBackgroundColor
            }
        }
    }
    // MARK: - Scan Result Indication
    
    func startTimerForBorderReset() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            if let overlayView = self.overlayView {
                overlayView.overlayColor = self.style.overlayFrameColor
                overlayView.overlayBackgroundColor = self.style.overlayBackgroundColor
            }
        }
    }
    
    func addRedBorder() {
        self.startTimerForBorderReset()
        
        if let overlayView = self.overlayView {
            overlayView.overlayColor = style.overlayErrorFrameColor
        }
    }
    
    func addGreenBorder() {
        self.startTimerForBorderReset()
        
        if let overlayView = self.overlayView {
            overlayView.overlayColor = style.overlayAcceptFrameColor
            if self.sound {
                AudioServicesPlaySystemSound(style.soundCode)
            }
//            1057 - tick!
////                1108    -    cameraShot
////                1350    -    RingerVibeChanged
////                1351    -    SilentVibeChanged
////                4095    -    Vibrate

        }
    }
    
    @objc public func setNeedsUpdateOrientation() {
        setNeedsDisplay()
        
        overlayView?.setNeedsDisplay()
        
        if let connection = reader?.previewLayer.connection, connection.isVideoOrientationSupported {
            let application                    = UIApplication.shared
            let orientation                    = UIDevice.current.orientation
            let supportedInterfaceOrientations = application.supportedInterfaceOrientations(for: application.keyWindow)
            
            connection.videoOrientation = CodeReader.videoOrientation(deviceOrientation: orientation, withSupportedOrientations: supportedInterfaceOrientations, fallbackOrientation: connection.videoOrientation)
        }
    }
    
    // MARK: - Convenience Methods
    
    private func addComponents() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.setNeedsUpdateOrientation), name: .UIDeviceOrientationDidChange, object: nil)
        
        addSubview(cameraView)
        
        if let overlayView = overlayView {
            addSubview(overlayView)
            overlayView.addSubview(btnClose)
            overlayView.addSubview(toolView)
        } else {
            cameraView.addSubview(btnClose)
            cameraView.addSubview(toolView)
        }
        
        if let reader = reader {
            cameraView.layer.insertSublayer(reader.previewLayer, at: 0)
            
            setNeedsUpdateOrientation()
        }
    }
    
    func readerDidStartScanning() {
        setNeedsUpdateOrientation()
        reader?.didStartScanning?()
    }
    
    func readerDidStopScanning() {}
}
