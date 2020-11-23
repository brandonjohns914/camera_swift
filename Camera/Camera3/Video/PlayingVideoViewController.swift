//
//  PlayingVideoViewController.swift
//  Camera3
//
//  Created by Brandon Johns on 11/11/20.
//

import AVKit
import MobileCoreServices
import UIKit

class PlayVideoViewController: UIViewController
{
    @IBOutlet weak var playvideoLabel: UILabel!
    @IBAction func playVideo(_ sender: AnyObject)
  {
    VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
  }
    
}

extension PlayVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,MediaInfo info: [UIImagePickerController.InfoKey: Any])
  {
    guard
      let media = info[UIImagePickerController.InfoKey.mediaType] as?String,
      media == (kUTTypeMovie as String),let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
      else { return }

    dismiss(animated: true)
    {
      let player = AVPlayer(url: url)
      let vcPlayer = AVPlayerViewController()
      vcPlayer.player = player
      self.present(vcPlayer, animated: true, completion: nil)
    }
  }
}


extension PlayVideoViewController: UINavigationControllerDelegate {
}
