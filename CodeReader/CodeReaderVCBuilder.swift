//
//  CodeReaderVCBuilder.swift
//  CodeReader
//
//  Created by Evgene Podkorytov on 19.07.2018.
//  Copyright © 2018 Podkorytov iEvgen. All rights reserved.
//

import Foundation
import UIKit

public final class CodeReaderVCBuilder {
    // MARK: - Configuring the CodeReaderVC Objects
    
    public typealias CodeReaderVCBuilderBlock = (CodeReaderVCBuilder) -> Void
    
    public var reader = CodeReader()
    
    public var readerView = CodeReaderContainer(displayable: CodeReaderView())
    
    public var startScanningAtLoad = true
    
    public var showOverlayView = true
    public var handleOrientationChange = true
    
    public var preferredStatusBarStyle: UIStatusBarStyle? = nil
    
    // MARK: - Initializing a View
    public init() {}
    
    public init(buildBlock: CodeReaderVCBuilderBlock) {
        buildBlock(self)
    }
}
