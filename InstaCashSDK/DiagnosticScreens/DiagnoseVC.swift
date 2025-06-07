//
//  DiagnoseVC.swift
//  InstaCash_Diagnostics
//
//  Created by Sameer Khan on 23/07/24.
//

import UIKit
import SwiftyJSON
import Foundation
import QRCodeReader
import os

open class DiagnoseVC: UIViewController, QRCodeReaderViewControllerDelegate {
    
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var lblVersionNum: UILabel!
    
    open var diagnoseFinish: ((_ resultString: String, _ metadata: JSON) -> Void)?
    open var fontFamilyName : String?
    open var fontFamilyType : String?
    open var AppGlobalColorHex : String?
    
    var arrFontType = ["Regular","Medium","Bold"]
    var resultJSON = JSON()
    
    lazy var reader: QRCodeReader = QRCodeReader()
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader          = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton = true
            
            $0.reader.stopScanningWhenCodeIsFound = false
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setStatusBarColor(themeColor: GlobalUtility().AppThemeColor)
        
        let bundle = Bundle.init(identifier: "in.instaWarehouse") ?? Bundle.main
        //print("bundle",bundle.bundleIdentifier ?? "bundle.bundleIdentifier")
        //print(bundle.bundlePath, bundle.bundleURL, bundle.isLoaded)
        
        if let strHex = self.AppGlobalColorHex {
            AppThemeColorHexString = strHex
        }
        
        if let globalFontName = self.fontFamilyName {
            AppFontFamilyName = globalFontName
        }
        
        //print("AppFontFamilyName is -", AppFontFamilyName ?? "font nahi mila")
        //AppFontFamilyName = self.fontFamilyName
        
        for font in arrFontType {
            let fontName = (self.fontFamilyName ?? "Roboto") + "-" + font
            //print("fontname is : ", fontName)
            
            self.registerFont(fontName, extension: fontFamilyType ?? "ttf", in: bundle)
        }
        
        //self.registerFont("Roboto-Regular", extension: "ttf", in: bundle)
        //self.registerFont("Roboto-Medium", extension: "ttf", in: bundle)
        //self.registerFont("Roboto-Bold", extension: "ttf", in: bundle)
          
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        lblVersionNum.text = appVersion
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        //AppOrientationUtility.lockOrientation(.portrait)
        appDelegate_Obj.orientationLock = .portrait
        
        self.setUIElementsProperties()
        
        self.changeLanguageOfUI()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: Custom Methods
    func changeLanguageOfUI() {
        
        //self.startBtn.setTitle(self.getLocalizatioStringValue(key: "Open SDK").uppercased(), for: .normal)
        self.startBtn.setTitle(self.getLocalizatioStringValue(key: "Start Diagnostics"), for: .normal)
        
    }
    
    func setUIElementsProperties() {
        
        self.startBtn.backgroundColor = AppThemeColor
        self.startBtn.layer.cornerRadius = AppBtnCornerRadius
        self.startBtn.setTitleColor(AppBtnTitleColor, for: .normal)
        self.startBtn.setTitle(self.getLocalizatioStringValue(key: "Start Diagnostics"), for: .normal)
        self.startBtn.titleLabel?.font = UIFont.init(name: AppFontMedium, size: self.startBtn.titleLabel?.font.pointSize ?? 18.0)
    }
    
    func registerFont(_ fontName: String, extension: String, in bundle: Bundle) {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: `extension`) else { return }
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, CTFontManagerScope.process, nil)
    }
    
    // MARK: - checkScanPermissions
    private func checkScanPermissions() -> Bool {
        do {
            return try QRCodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: self.getLocalizatioStringValue(key: "Error"), message: self.getLocalizatioStringValue(key: "This app is not authorized to use Back Camera."), preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "Setting"), style: .default, handler: { (_) in
                    
                    DispatchQueue.main.async {
                     
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if #available(iOS 10.0, *) {
                                
                                UIApplication.shared.open(settingsUrl, options: [:]) { (success) in
                                    
                                }
                                
                            } else {
                                // Fallback on earlier versions
                                UIApplication.shared.openURL(settingsUrl)
                            }
                        }
                        
                    }
                    
                }))
                
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "Cancel"), style: .cancel, handler: nil))
                
            default:
                alert = UIAlertController(title: self.getLocalizatioStringValue(key: "Error"), message: self.getLocalizatioStringValue(key: "Reader not supported by the current device"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "OK"), style: .cancel, handler: nil))
            }
            
            present(alert, animated: true, completion: nil)
            
            return false
        }
    }

    func showAlertWithTextField(on viewController: UIViewController) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Enter User ID", message: "Please enter USER-ID below:", preferredStyle: .alert)
        
        // Add a text field to the alert
        alertController.addTextField { textField in
            textField.placeholder = "Enter user id..."
        }
        
        // Add actions (OK and Cancel)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let text = alertController.textFields?.first?.text {
                print("User entered: \(text)")
                // Do something with the text
                AppUserDefaults.setValue(text, forKey: "userId")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Add actions to the alert
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the alert
        viewController.present(alertController, animated: true, completion: nil)
    }

    
    // MARK: IBActions
    @IBAction func scanQRButtonPressed(_ sender: UIButton) {
                
        DispatchQueue.main.async {
            
            guard self.checkScanPermissions() else { return }
            
            //self.readerVC.modalPresentationStyle = .formSheet
            self.readerVC.modalPresentationStyle = .overFullScreen
            self.readerVC.delegate               = self
            
            self.readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                if let result = result {
                    
                    let completeResult = String(result.value)
                    print("QRReader Result is:-" , completeResult)
                    
                    AppUserDefaults.setValue(completeResult, forKey: "userId")
                   
                }
            }
        }
        
        present(readerVC, animated: true, completion: nil)
        
    }
    
    @IBAction func manualEnterButtonPressed(_ sender: UIButton) {
        self.showAlertWithTextField(on: self)
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        
        //NSLog("723263045@warehouse: ", "WiFi")
        //NSLog("%@%@", "Warehouse", "WiFi = 1")
        
        //let bundle = Bundle.init(identifier: "in.instaWarehouse")
        //let storyboard = UIStoryboard(name: "InstaCash", bundle: bundle)
        
        if AppUserDefaults.value(forKey: "userId") != nil {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
            self.navigationController?.pushViewController(vc, animated: true)
            
        }
        else {
            
            DispatchQueue.main.async {
                self.view.makeToast(self.getLocalizatioStringValue(key: "Please Scan QR-Code to fetch User ID or manually enter User ID"), duration: 2.0, position: .top)
            }
            
        }
        
            
        
        //vc.modalPresentationStyle = .overFullScreen
        //vc.modalTransitionStyle = .flipHorizontal
        //self.present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: QRCodeReader Delegate Methods
    
    public func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        self.readerVC.dismiss(animated: true)
      
    }
    
    public func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        self.readerVC.dismiss(animated: true)
     
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
}
