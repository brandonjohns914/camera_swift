//
//  PhotoPreview.swift
//  Camera
//
//  Created by Brandon Johns on 11/11/20.
//

import UIKit
import Photos

class PhotoPreview: UIView {
    /// preview picture
    let pictureViews: UIImageView =
    {
        let pictureView = UIImageView(frame: .zero)
        pictureView.contentMode = .scaleAspectFill
        pictureView.clipsToBounds = true
        return pictureView
    }()

    var cancelButton: UIButton =
        {
        let cancelbut = UIButton(type: .system)
        cancelbut.setTitle( "❌❌", for: .normal)
        cancelbut.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        cancelbut.tintColor = .systemRed
        return cancelbut
    }()
    
    var saveButton: UIButton =
        {
        let savebut = UIButton(type: .system)
            savebut.setTitle("☑️☑️", for: .normal)
            savebut.addTarget(self, action: #selector(handleSavePhoto), for: .touchUpInside)
            savebut.tintColor = .systemGray
        return savebut
    }()
    
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        addSubviews(pictureViews, cancelButton, saveButton)
        //// picture
        pictureViews.makeConstraints(top: topAnchor, left: leftAnchor, right: rightAnchor, bottom: bottomAnchor, topMargin: 0, leftMargin: 0, rightMargin: 0, bottomMargin: 0, width: 0, height: 0)
        
        /// cancel
        cancelButton.makeConstraints(top: safeAreaLayoutGuide.topAnchor, left: nil, right: rightAnchor, bottom: nil, topMargin: 15, leftMargin: 0, rightMargin: 15, bottomMargin: 0, width: 50, height: 50)
        /// save
        saveButton.makeConstraints(top: nil, left: nil, right: cancelButton.leftAnchor, bottom: nil, topMargin: 0, leftMargin: 0, rightMargin: 5, bottomMargin: 0, width: 50, height: 50)
        saveButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor).isActive = true
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    @objc private func handleCancel() {
        
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
    
    @objc private func handleSavePhoto()
    {
    guard let previewImage = self.pictureViews.image else
    {
        return
    }
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        PHAssetChangeRequest.creationRequestForAsset(from: previewImage)
                        print("Pictures Saved! ")
                        self.handleCancel()
                    }
                } catch let error {
                    print("Picture did not save: ", error)
                }
            } else {
                print("premission error")
            }
        }
    }
}
