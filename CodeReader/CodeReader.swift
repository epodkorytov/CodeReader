//
//  CodeReader.swift
//  CodeReader
//

import UIKit
import AVFoundation


public struct CodeReaderResult {
    public let description: String
    public let objectType: String
}

public final class CodeReader: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    private var objectTypes: [AVMetadataObject.ObjectType] { return [  AVMetadataObject.ObjectType.upce,
                                                               AVMetadataObject.ObjectType.code39,
                                                               AVMetadataObject.ObjectType.code39Mod43,
                                                               AVMetadataObject.ObjectType.code93,
                                                               AVMetadataObject.ObjectType.code128,
                                                               AVMetadataObject.ObjectType.ean8,
                                                               AVMetadataObject.ObjectType.ean13,
                                                               AVMetadataObject.ObjectType.aztec,
                                                               AVMetadataObject.ObjectType.pdf417,
                                                               AVMetadataObject.ObjectType.itf14,
                                                               AVMetadataObject.ObjectType.dataMatrix,
                                                               AVMetadataObject.ObjectType.interleaved2of5,
                                                               AVMetadataObject.ObjectType.qr] }
    
    private let sessionQueue         = DispatchQueue(label: "session queue")
    private let metadataObjectsQueue = DispatchQueue(label: "metadataObjectsQueue", attributes: [], target: nil)
    
    var defaultDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video)
    
    
    lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
        guard let defaultDevice = defaultDevice else { return nil }
        
        return try? AVCaptureDeviceInput(device: defaultDevice)
    }()
    
    public var metadataOutput = AVCaptureMetadataOutput()
    var session               = AVCaptureSession()
    
    // MARK: - Managing the Properties
    
    /// CALayer that you use to display video as it is being captured by an input device.
    public let previewLayer: AVCaptureVideoPreviewLayer
    
    // MARK: - Managing the Code Discovery
    
    /// Flag to know whether the scanner should stop scanning when a code is found.
    public var stopScanningWhenCodeIsFound: Bool = true
    
    /// Block is executed when a metadata object is found.
    public var didFindCode: ((CodeReaderResult) -> Void)?
    
    /// Block is executed when a found metadata object string could not be decoded.
    public var didFailDecoding: (() -> Void)?
    
    public var didStartScanning: (() -> Void)?
    public var didStopScanning: (() -> Void)?
    public var didCancel: (() -> Void)?
    //
    public var rectOfInterest: CGRect? {
        didSet {
            if let rectOfInterest = self.rectOfInterest {
                DispatchQueue.global().async {
                    self.metadataOutput.rectOfInterest = self.previewLayer.metadataOutputRectConverted(fromLayerRect: rectOfInterest)
                }
            }
        }
    }
    
    
    // MARK: - Creating the Code Reade
    
    
    public override init() {
        previewLayer        = AVCaptureVideoPreviewLayer(session: session)
        super.init()
        
        sessionQueue.async {
            self.configureDefaultComponents()
        }
    }
    
    // MARK: - Initializing the AV Components
    
    private func configureDefaultComponents() {
        for output in session.outputs {
            session.removeOutput(output)
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // Add video input
        if let _defaultDeviceInput = defaultDeviceInput {
            session.addInput(_defaultDeviceInput)
        }
        
        // Add metadata output
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
        
        let allTypes = Set(metadataOutput.availableMetadataObjectTypes)
        let filtered = objectTypes.filter { (mediaType) -> Bool in
            allTypes.contains(mediaType)
        }
        
        
        metadataOutput.metadataObjectTypes = filtered
        previewLayer.videoGravity          = .resizeAspectFill
        
        session.commitConfiguration()
    }
    
    // MARK: - Controlling Reader
    
    /**
     Starts scanning the codes.
     
     *Notes: if `stopScanningWhenCodeIsFound` is sets to true (default behaviour), each time the scanner found a code it calls the `stopScanning` method.*
     */
    public func startScanning() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.toggleTorch(self.isTogglingTorch)
                self.didStartScanning?()
            }
        }
    }
    
    /// Stops scanning the codes.
    public func stopScanning() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                self.didStopScanning?()
            }
        }
    }
    
    /**
     Indicates whether the session is currently running.
     
     The value of this property is a Bool indicating whether the receiver is running.
     Clients can key value observe the value of this property to be notified when
     the session automatically starts or stops running.
     */
    public var isRunning: Bool {
        return session.isRunning
    }
    
    
    public var isTorchAvailable: Bool {
        return defaultDevice?.isTorchAvailable ?? false
    }
    
    /**
     Toggles torch on the default device.
     */
    public var torchLevel: Float = 0.15
    public var isTogglingTorch: Bool = false
    public func toggleTorch(_ state: Bool) {
        if isTorchAvailable {
            do {
                try defaultDevice?.lockForConfiguration()
                
                if state {
                    try? defaultDevice?.setTorchModeOn(level: torchLevel)
                } else {
                    defaultDevice?.torchMode = .off
                }
                
                self.isTogglingTorch = state
                defaultDevice?.unlockForConfiguration()
            }
            catch _ {
                self.isTogglingTorch = false
            }
        }
        
    }
    
    // MARK: - Managing the Orientation
    
    /**
     Returns the video orientation corresponding to the given device orientation.
     
     - parameter orientation: The orientation of the app's user interface.
     - parameter supportedOrientations: The supported orientations of the application.
     - parameter fallbackOrientation: The video orientation if the device orientation is FaceUp or FaceDown.
     */
    public class func videoOrientation(deviceOrientation orientation: UIDeviceOrientation, withSupportedOrientations supportedOrientations: UIInterfaceOrientationMask, fallbackOrientation: AVCaptureVideoOrientation? = nil) -> AVCaptureVideoOrientation {
        let result: AVCaptureVideoOrientation
        
        switch (orientation, fallbackOrientation) {
        case (.landscapeLeft, _):
            result = .landscapeRight
        case (.landscapeRight, _):
            result = .landscapeLeft
        case (.portrait, _):
            result = .portrait
        case (.portraitUpsideDown, _):
            result = .portraitUpsideDown
        case (_, .some(let orientation)):
            result = orientation
        default:
            result = .portrait
        }
        
        if supportedOrientations.contains(orientationMask(videoOrientation: result)) {
            return result
        }
        else if let orientation = fallbackOrientation , supportedOrientations.contains(orientationMask(videoOrientation: orientation)) {
            return orientation
        }
        else if supportedOrientations.contains(.portrait) {
            return .portrait
        }
        else if supportedOrientations.contains(.landscapeLeft) {
            return .landscapeLeft
        }
        else if supportedOrientations.contains(.landscapeRight) {
            return .landscapeRight
        }
        else {
            return .portraitUpsideDown
        }
    }
    
    class func orientationMask(videoOrientation orientation: AVCaptureVideoOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        }
    }
    
    // MARK: - Checking the Reader Availabilities
    
    /**
     Checks whether the reader is available.
     
     - returns: A boolean value that indicates whether the reader is available.
     */
    public class func isAvailable() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return false }
        
        return (try? AVCaptureDeviceInput(device: captureDevice)) != nil
    }
    
    /**
     Checks and return whether the given metadata object types are supported by the current device.
     
     - parameter metadataTypes: An array of objects identifying the types of metadata objects to check.
     
     - returns: A boolean value that indicates whether the device supports the given metadata object types.
     */
    public class func supportsMetadataObjectTypes(_ metadataTypes: [AVMetadataObject.ObjectType]? = nil) throws -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw NSError(domain: "AVCaptureDevice.error", code: -1001, userInfo: nil)
        }
        
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        let output      = AVCaptureMetadataOutput()
        let session     = AVCaptureSession()
        
        session.addInput(deviceInput)
        session.addOutput(output)
        
        var metadataObjectTypes = metadataTypes
        
        if metadataObjectTypes == nil || metadataObjectTypes?.count == 0 {
            // Check the QRCode metadata object type by default
            metadataObjectTypes = [.qr, .interleaved2of5]
        }
        
        for metadataObjectType in metadataObjectTypes! {
            if !output.availableMetadataObjectTypes.contains { $0 == metadataObjectType } {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - AVCaptureMetadataOutputObjects Delegate Methods
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        sessionQueue.async { [weak self] in
            guard let weakSelf = self else { return }

            for current in metadataObjects {
                if let _readableCodeObject = current as? AVMetadataMachineReadableCodeObject {
                    if _readableCodeObject.stringValue != nil {
                        if weakSelf.objectTypes.contains(_readableCodeObject.type) {
                            guard weakSelf.session.isRunning, let sVal = _readableCodeObject.stringValue else { return }

                            if weakSelf.stopScanningWhenCodeIsFound {
                                weakSelf.session.stopRunning()

                                DispatchQueue.main.async {
                                    weakSelf.didStopScanning?()
                                }
                            }

                            let scannedResult = CodeReaderResult(description: sVal, objectType:_readableCodeObject.type.rawValue)

                            DispatchQueue.main.async {
                                weakSelf.didFindCode?(scannedResult)
                            }
                        }
                    }
                }
                else {
                    weakSelf.didFailDecoding?()
                }
            }
        }
    }
}


