//
//  EnterViewController.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreML
import Vision

class EnterViewController: UIViewController {
    
    private static let kControlHeight = Int(128.0)
    
    private var avCaptureSession: AVCaptureSession!
    private var avCaptureDeviceInput: AVCaptureDeviceInput!
    private var avCaptureOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var previewView: UIView!
    private var captureOutputQueue = DispatchQueue(label: "cameraQueue")
    private var waitingForCapture = false
    private var captureButton: UIButton!
    
    private var requests = [VNRequest]()
    
    private var infoLabel: UILabel!
    private var detailsView: FoodDetailsView!

    private var kButtonTop  = Int(64.0)
    private var kButtonHeight  = CGFloat(128.0)
    private var kButtonWidth  = CGFloat(128.0)
    private var kButtonLeft  = Int(32.0)
    private let kControlsHeight = CGFloat(256.0)
    
    private var drawerHeightConstraint: NSLayoutConstraint!
    
    private var lastCapturedImage: UIImage!
    
    private var afterViewAppears: ()->Void = {}
    
    static let kCapturePrefix = "snacktrackerCaptureImage"
    
    static var saveDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths[0]
    }
    
    // MARK: -- methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avCaptureSession = AVCaptureSession()
        
        avCaptureSession?.sessionPreset = .vga640x480
        
        previewView = UIView(frame: CGRect.zero)
        
        view.addSubview(previewView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
        
        previewView?.alpha = 0.0
        captureButton?.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 2.0) {
            [weak self] in
            
            self?.previewView.alpha = 1.0
            self?.captureButton.alpha = 1.0
        }
        
        afterViewAppears()
    }
    
    private func setupView() {
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video),
            let avCaptureDeviceInput = try? AVCaptureDeviceInput(device: backCamera),
            let captureSession = avCaptureSession,
            let previewView = previewView
            else {
                print("Unable to access back camera!")
                return
        }
        
        avCaptureSession?.addInput(avCaptureDeviceInput)
        
        avCaptureOutput.setSampleBufferDelegate(self, queue: captureOutputQueue)
        avCaptureSession?.addOutput(avCaptureOutput)
        
        previewView.frame = view.bounds
    
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        self.previewLayer = previewLayer
        
        previewView.layer.addSublayer(previewLayer)

        previewView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(previewLayer)
        previewLayer.frame = previewView.bounds
        
        avCaptureSession?.startRunning()
        
        // control stack view above camera preview view
        detailsView = FoodDetailsView()
        detailsView.translatesAutoresizingMaskIntoConstraints = false
        detailsView.delegate = self
        detailsView.isHidden = true
    
        view.addSubview(detailsView)
        drawerHeightConstraint = detailsView.heightAnchor.constraint(equalToConstant: kControlsHeight)
        detailsView.addConstraint(drawerHeightConstraint)
        
        view.addConstraints([
            detailsView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 32),
            detailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            detailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        
        // button for capture
        captureButton = UIButton()
        captureButton.setImage(UIImage(named: "camera"), for: .normal)
        captureButton.contentMode = .scaleAspectFit
        captureButton.backgroundColor = UIColor.gray.withAlphaComponent(0.25)
        captureButton.layer.cornerRadius = 8.0
        captureButton.addTarget(self, action: #selector(onCapture(_:)), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)
        
        captureButton.addConstraints([
            captureButton.heightAnchor.constraint(equalToConstant: kButtonHeight),
            captureButton.widthAnchor.constraint(equalToConstant: kButtonWidth)
        ])
        
        view.addConstraints([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -128)
        ])
        
        view.bringSubviewToFront(detailsView)
        view.backgroundColor = UIColor.white
    }
    
    func showLoggedItem(_ path: URL) {
        
        afterViewAppears = { [weak self] in
            self?.setupLogView(path)
        }
    }
    
    private func setupLogView(_ path: URL) {
        
        captureButton.isHidden = true
        
        detailsView.cancelButton.isHidden = true
        detailsView.saveButton.isHidden = true
        detailsView.isHidden = false
        
        previewLayer.session?.stopRunning()
        previewView.isHidden = true
        
        if let details = FoodLog.shared.retrieveDetails(forImageAtPath: path) {
            detailsView.nameField.text = details.name
            if let time = details.time {
                detailsView.timeField.text = FoodLog.shared.dateFormatter.string(from: time)
            }
            detailsView.servingSizeField.text = details.servingSize
            detailsView.serverTagField.text = details.tag
            detailsView.saveButton.isEnabled = false
            if let type = details.type {
                detailsView.mealTypeField.selectedSegmentIndex = FoodDetailsView.allMealTypes.firstIndex(of: type)!
            }
        }
        
        let imageView = UIImageView()
        imageView.image = try? UIImage(data: Data(contentsOf: path))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        view.addConstraints([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        view.bringSubviewToFront(imageView)
        view.bringSubviewToFront(detailsView)
    }
}

// MARK: -- AVCaptureVideoDataOutputSampleBufferDelegate
extension EnterViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        if waitingForCapture {
            waitingForCapture = false
            
            lastCapturedImage = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer), scale: 1.0, orientation: .right)
            
            previewLayer.session?.stopRunning()
        }
    }
}

// MARK: -- FoodDetailsViewDelegate
extension EnterViewController: FoodDetailsViewDelegate {
    func onSave(_ foodDetails: FoodDetailsModel) {
        
        guard let imageURL = writeImageToDocumentsWithLabel(lastImage) else {
            fatalError()
        }
        
        FoodLog.shared.saveDetails(forImageAtPath: imageURL, details: foodDetails)
        
        previewLayer.session?.startRunning()
        
        navigationController?.popViewController(animated: true)
    }
    
    var lastImage: UIImage! {
        return self.lastCapturedImage
    }
    
    func onCancel() {
        detailsView.isHidden = true
        lastCapturedImage = nil
        previewLayer.session?.startRunning()
    }
}

// MARK: -- helpers
extension EnterViewController {
    
    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

// MARK: -- button handler
extension EnterViewController {
    
    @objc private func onCapture(_ sender: Any) {
        print("capturing...")
        
        waitingForCapture = true
        
        detailsView.isHidden = false
    }
    
    private func writeImageToDocumentsWithLabel(_ image: UIImage) -> URL? {
        
        let documentsURL = FoodLog.shared.logPath
        
        if let data = image.jpegData(compressionQuality: 1.0) {
            do {
                let secsSinceEpoch = Date() - Date.timeIntervalBetween1970AndReferenceDate
                let path = documentsURL.appendingPathComponent("\(EnterViewController.kCapturePrefix).\(secsSinceEpoch).jpg")
                try data.write(to: path)
                print("wrote image data to \(path)")
                return path
            }
            catch {
                print("failed to write image data")
                return nil
            }
        }
        return nil
    }
}
