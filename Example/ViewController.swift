//
//  ViewController.swift
//  Example
//
//  Created by Evgene Podkorytov on 17.07.2018.
//  Copyright © 2018 Podkorytov iEvgen. All rights reserved.
//

import UIKit
import CodeReader
import Indicator

class ViewController: UIViewController {

    lazy var readerVC: CodeReaderVC = {
        let builder = CodeReaderVCBuilder {
            $0.reader                  = CodeReader()
            $0.preferredStatusBarStyle = .lightContent
            
            $0.reader.stopScanningWhenCodeIsFound = false
        }
        
        return CodeReaderVC(builder: builder)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
    
        super.viewDidAppear(animated)
        guard checkScanPermissions() else { return }
        
        readerVC.modalPresentationStyle = .formSheet
        readerVC.completionBlock = { (result: CodeReaderResult?) in
            if let result = result {
                print("Completion with result: \(result.description) of type \(result.objectType)")
                
                if let readerView = self.readerVC.readerView.displayable as? CodeReaderView {
                    let indicator = Indicator(style: IndicatorStyleDefault())
                        indicator.progress = 0.75
                    readerView.showAlert(.indicator(indicator))
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                    if let readerView = self.readerVC.readerView.displayable as? CodeReaderView {
                        readerView.showAlert(.accept(title: "УСПЕШНО", message: "Подкорытов Евений Владимирович\n123456789101112"))
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                            readerView.showAlert(.error(title: "БИЛЕТ НЕ Существует", message: nil))
                            
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                                readerView.showAlert(.warning(title: "БИЛЕТ использован", message: "Подкорытов Евений Владимирович\n123456789"))
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                                    readerView.hideAlert()
                                    self.readerVC.startScanning()
                                }
                            }
                        }
                    }
                    
                }
                
            }
        }
        readerVC.didCancel = {
            self.readerVC.dismiss(animated: true, completion: nil)
        }
        
        readerVC.buttons = [.custom(image: UIImage(named: "search")!, action: {
            print("search Tap!")
        }), .light, .sound]
        //navigationController?.pushViewController(readerVC, animated: true)
        present(readerVC, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    private func checkScanPermissions() -> Bool {
        do {
            return try CodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            default:
                alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            }
            
            present(alert, animated: true, completion: nil)
            
            return false
        }
    }
}

