//
//  CameraController.swift
//  Camera3
//
//  Created by Brandon Johns on 11/11/20.
//

import UIKit
import AVFoundation

class CameraController: UIViewController, AVCapturePhotoCaptureDelegate
{

 
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
    }
    private let photoOutput = AVCapturePhotoOutput()
    
    @IBOutlet weak var takepic: UIButton!
    
    
    private func setupUI() {
        
        view.addSubviews( takepic)
        
        takepic.makeConstraints(top: nil, left: nil, right: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, topMargin: 0, leftMargin: 0, rightMargin: 0, bottomMargin: 25, width: 100, height: 100)
        takepic.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
 
    @IBAction func takePicture(_ sender: Any)
    {
        takepic.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)
    }
    
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // the user has already authorized to access the camera.
            self.setupCaptureSession()
            
        case .notDetermined: // the user has not yet asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted { // if user has granted to access the camera.
                    print("Camera has Premission")
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                } else
                {
                    print("No Premission to the Camera")
                    self.handleDismiss()
                }
            }
            
        case .denied:
            print("Camera access denied ")
            self.handleDismiss()
            
        case .restricted:
            print("Restricted access to camera ")
            self.handleDismiss()
            
        default:
            print("Error in accessing the camera ")
            self.handleDismiss()
        }
    }
    
    private func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        if let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch let error {
                print("Failed access: \(error)")
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.frame = self.view.frame
            cameraLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(cameraLayer)
            
            captureSession.startRunning()
            self.setupUI()
        }
    }
    
    @objc private func handleDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func handleTakePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let previewImage = UIImage(data: imageData)
        
        let photoPreviewContainer = PhotoPreview(frame: self.view.frame)
        photoPreviewContainer.pictureViews.image = previewImage
        self.view.addSubviews(photoPreviewContainer)
    }
}
