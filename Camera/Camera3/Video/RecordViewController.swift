//
//  RecordViewController.swift
//  Camera3
//
//  Created by Brandon Johns on 11/11/20.
//

import MobileCoreServices
import UIKit

class RecordVideoViewController: UIViewController
{
    @IBOutlet weak var recordVideoLabel: UILabel!
    
  @objc func video(_ videoPath: String, Error error: Error?,contextInfo info: AnyObject)
  {
    let title = (error == nil) ? "Success" : "Error"
    let message = (error == nil) ? "Video was saved" : "Video failed to save"

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert); alert.addAction(UIAlertAction(title: "Works", style: UIAlertAction.Style.cancel, handler: nil))
    present(alert, animated: true, completion: nil)
  }

  @IBAction func record(_ sender: AnyObject)
  {
    VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
  }
}


extension RecordVideoViewController: UIImagePickerControllerDelegate
{
  func imagePickerController(_ picker: UIImagePickerController,  Info info: [UIImagePickerController.InfoKey: Any]) {
    dismiss(animated: true, completion: nil)

    guard
      let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
      mediaType == (kUTTypeMovie as String), let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL, UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
      else { return }

    // Handle a movie capture
    UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(video(_: Error: contextInfo:)), nil)
  }
}

extension RecordVideoViewController: UINavigationControllerDelegate {
}
