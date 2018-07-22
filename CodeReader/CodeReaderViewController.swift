//
//  CodeReaderViewController.swift
//  CodeReader
//
//  Created by Evgene Podkorytov on 19.07.2018.
//  Copyright © 2018 Podkorytov iEvgen. All rights reserved.
//

import UIKit
import AVFoundation

open class CodeReaderVC: UIViewController {
    /// The code reader object used to scan the bar code.
    public let codeReader: CodeReader
    
    public let readerView: CodeReaderContainer
    let startScanningAtLoad: Bool
    let customPreferredStatusBarStyle: UIStatusBarStyle?
    
    public var buttons: Array<CodeReaderAction> = Array<CodeReaderAction>() {
        didSet {
            if let readerView = readerView.displayable as? CodeReaderView {
                readerView.buttons = buttons
            }
        }
    }
    
    // MARK: - Managing the Callback Responders
    
    
    /// The completion blocak that will be called when a result is found.
    public var completionBlock: ((CodeReaderResult?) -> Void)?
    public var didCancel: (() -> Void)?
    
    deinit {
        codeReader.stopScanning()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Creating the View Controller
    
    required public init(builder: CodeReaderVCBuilder) {
        readerView                    = builder.readerView
        startScanningAtLoad           = builder.startScanningAtLoad
        codeReader                    = builder.reader
        customPreferredStatusBarStyle = builder.preferredStatusBarStyle
        
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .black
        
        codeReader.didFindCode = { [weak self] resultAsObject in
            if let weakSelf = self {
                if let readerView = weakSelf.readerView.displayable as? CodeReaderView {
                    readerView.addGreenBorder()
                }
                weakSelf.completionBlock?(resultAsObject)
                //weakSelf.didScanResult?(resultAsObject)
            }
        }
        
        codeReader.didFailDecoding = { [weak self] in
            if let weakSelf = self {
                if let readerView = weakSelf.readerView.displayable as? CodeReaderView {
                    readerView.addRedBorder()
                }
            }
        }
        
        codeReader.didCancel = { [weak self] in
            if let weakSelf = self {
                weakSelf.codeReader.stopScanning()
                weakSelf.didCancel?()
            }
        }
        
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        codeReader                    = CodeReader()
        readerView                    = CodeReaderContainer(displayable: CodeReaderView())
        startScanningAtLoad           = false
        customPreferredStatusBarStyle = nil
        
        super.init(coder: aDecoder)
    }
    
    // MARK: - Responding to View Events
    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.avCaptureInputPortFormatDescriptionDidChangeNotification(notification:)), name: .AVCaptureInputPortFormatDescriptionDidChange, object: nil)
    }
    
    @objc func avCaptureInputPortFormatDescriptionDidChangeNotification(notification: NSNotification) {
        self.codeReader.rectOfInterest = self.readerView.displayable.overlayView?.captureFrame
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if startScanningAtLoad {
            readerView.displayable.setNeedsUpdateOrientation()
            
            startScanning()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        
        super.viewWillDisappear(animated)
        
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        codeReader.previewLayer.frame = view.bounds
        
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return customPreferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    // MARK: - Initializing the AV Components
    
    private func setupUI() {
        view.addSubview(readerView.view)
        readerView.view.translatesAutoresizingMaskIntoConstraints = false
        readerView.setupComponents(codeReader)
        
        // Setup constraints
        
        for attribute in [.left, .top, .right] as [NSLayoutAttribute] {
            NSLayoutConstraint(item: readerView.view, attribute: attribute, relatedBy: .equal, toItem: view, attribute: attribute, multiplier: 1, constant: 0).isActive = true
        }

        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: readerView.view.bottomAnchor).isActive = true

        // Add buttons
        if let readerView = readerView.displayable as? CodeReaderView {
            readerView.buttons = []
        }
    }
    
    // MARK: - Controlling the Reader
    
    /// Starts scanning the codes.
    public func startScanning() {
        codeReader.startScanning()
    }
    
    /// Stops scanning the codes.
    public func stopScanning() {
        codeReader.stopScanning()
    }
    
    // MARK: - Catching Button Events
    
    
}
