//
//  CodeReaderStyle.swift
//  CodeReader
//


import UIKit
import AVKit

public protocol CodeReaderStyleProtocol {
    var iconColor: UIColor { get set }
    var showOverlay: Bool { get set }
    var overlayFrameColor: UIColor { get set }
    var overlayBackgroundColor: UIColor { get set }
    
    var torchLevel: Float { get set }
    var soundCode: SystemSoundID { get set }
    
    var titleFont: UIFont { get set }
    var messageFont: UIFont { get set }
    
    var overlayAcceptFrameColor: UIColor { get set }
    var overlayAcceptBackgroundColor: UIColor { get set }
    var acceptTitleColor: UIColor { get set }
    var acceptMsgColor: UIColor { get set }
    
    
    var overlayErrorFrameColor: UIColor { get set }
    var overlayErrorBackgroundColor: UIColor { get set }
    var errorTitleColor: UIColor { get set }
    var errorMsgColor: UIColor { get set }
    
    var overlayWarningFrameColor: UIColor { get set }
    var overlayWarningBackgroundColor: UIColor { get set }
    var warningTitleColor: UIColor { get set }
    var warningMsgColor: UIColor { get set }
}

public struct CodeReaderStyleDefault: CodeReaderStyleProtocol {
    public var iconColor: UIColor = .white
    public var showOverlay: Bool = true
    public var overlayFrameColor: UIColor = .white
    public var overlayBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.6)
    public var torchLevel: Float = 0.15
    public var soundCode: SystemSoundID = 1057
    
    public var titleFont: UIFont = UIFont(name: "Helvetica-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 22)
    public var messageFont: UIFont = UIFont(name: "Helvetica", size: 18) ?? UIFont.systemFont(ofSize: 18)
    
    public var overlayAcceptFrameColor: UIColor = .green
    public var overlayAcceptBackgroundColor: UIColor = UIColor.green.withAlphaComponent(0.6)
    public var acceptTitleColor: UIColor = .white
    public var acceptMsgColor: UIColor = .white
    
    public var overlayErrorFrameColor: UIColor = .red
    public var overlayErrorBackgroundColor: UIColor = UIColor.red.withAlphaComponent(0.6)
    public var errorTitleColor: UIColor = .white
    public var errorMsgColor: UIColor = .white
    
    public var overlayWarningFrameColor: UIColor = .orange
    public var overlayWarningBackgroundColor: UIColor = UIColor.orange.withAlphaComponent(0.6)
    public var warningTitleColor: UIColor = .white
    public var warningMsgColor: UIColor = .white
}
