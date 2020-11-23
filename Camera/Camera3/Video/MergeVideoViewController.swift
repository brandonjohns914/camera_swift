//
//  MergeVideoViewController.swift
//  Camera3
//
//  Created by Brandon Johns on 11/22/20.
//

import MediaPlayer
import MobileCoreServices
import Photos
import UIKit

class MergeVideoViewController: UIViewController
{
    
    ///labels
    @IBOutlet weak var createownvideolabel: UILabel!
    @IBOutlet weak var uploadvideo1label: UILabel!
    @IBOutlet weak var createonVideoLabel: UILabel!
    @IBOutlet weak var secondVideolabel: UILabel!
    @IBOutlet weak var savevideoLabel: UILabel!
    
    
var vid1: AVAsset?
  var vid2: AVAsset?
  var audio: AVAsset?
  var combo  = false

  @IBOutlet var activityMonitor: UIActivityIndicatorView!

  func exportDidFinish(_ session: AVAssetExportSession) {
    // Cleanup assets
    activityMonitor.stopAnimating()
    vid1 = nil
    vid2 = nil
    audio = nil

    guard
      session.status == AVAssetExportSession.Status.completed,
      let outputURL = session.outputURL
      else { return }

    let saveVideoToPhotos =
        {
    let changes: () -> Void =
        {
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
    }
        
    PHPhotoLibrary.shared().performChanges(changes) { saved, error in
      DispatchQueue.main.async {
        let success = saved && (error == nil)
        let title = success ? "Success" : "Error"
        let message = success ? "Video has been saved " : "Video was not saved"

        let alert = UIAlertController(
          title: title,
          message: message,
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "Works",
          style: UIAlertAction.Style.cancel,
          handler: nil))
        self.present(alert, animated: true, completion: nil)
      }
    }
    }

    // Ensure permission to access Photo Library
    if PHPhotoLibrary.authorizationStatus() != .authorized {
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          saveVideoToPhotos()
        }
      }
    } else {
      saveVideoToPhotos()
    }
  }

  func savedPhotosAvailable() -> Bool {
    guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
      else { return true }

    let alert = UIAlertController(
      title: "Not Found",
      message: "Cant find an ablum",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(
      title: "OK",
      style: UIAlertAction.Style.cancel,
      handler: nil))
    present(alert, animated: true, completion: nil)
    return false
  }

  @IBAction func loadAssetOne(_ sender: AnyObject)
  {
    if savedPhotosAvailable()
    {
      combo = true
      VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
  }

  @IBAction func loadAssetTwo(_ sender: AnyObject)
  {
    if savedPhotosAvailable()
    {
      combo = false
      VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
  }

  @IBAction func loadAudio(_ sender: AnyObject) {
    let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
    mediaPickerController.delegate = self
    mediaPickerController.prompt = "Select Audio"
    present(mediaPickerController, animated: true, completion: nil)
  }

  // swiftlint:disable:next function_body_length
  @IBAction func merge(_ sender: AnyObject) {
    guard
      let firstAsset = vid1,
      let secondAsset = vid2
      else { return }

    activityMonitor.startAnimating()

    // 1 - Create AVMutableComposition object. This object
    // will hold your AVMutableCompositionTrack instances.
    let mixComposition = AVMutableComposition()

    // 2 - Create two video tracks
    guard
      let firstTrack = mixComposition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
      else { return }

    do {
      try firstTrack.insertTimeRange(
        CMTimeRangeMake(start: .zero, duration: firstAsset.duration),
        of: firstAsset.tracks(withMediaType: .video)[0],
        at: .zero)
    } catch {
      print("Failed to load first video")
      return
    }

    guard
      let secondTrack = mixComposition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
      else { return }

    do {
      try secondTrack.insertTimeRange(
        CMTimeRangeMake(start: .zero, duration: secondAsset.duration),
        of: secondAsset.tracks(withMediaType: .video)[0],
        at: firstAsset.duration)
    } catch {
      print("Failed to load second video")
      return
    }


    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRangeMake(
      start: .zero,
      duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))


    let firstInstruction = VideoHelper.videoCompositionInstruction(firstTrack, asset: firstAsset)
    firstInstruction.setOpacity(0.0, at: firstAsset.duration)
    let secondInstruction = VideoHelper.videoCompositionInstruction(secondTrack, asset: secondAsset)

    
    mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = [mainInstruction]
    mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    mainComposition.renderSize = CGSize(
      width: UIScreen.main.bounds.width,
      height: UIScreen.main.bounds.height)

    if let loadedAudioAsset = audio
    {
      let audioTrack = mixComposition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: 0)
      do {
        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration)),
          of: loadedAudioAsset.tracks(withMediaType: .audio)[0],at: .zero)
      }
      catch
      {
        print("Failed to load Audio")
      }
    }

  
    guard
      let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      else { return }
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    let date = dateFormatter.string(from: Date())
    let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

    guard let exporter = AVAssetExportSession( asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
      else { return }
    exporter.outputURL = url
    exporter.outputFileType = AVFileType.mov
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = mainComposition

    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        self.exportDidFinish(exporter)
      }
    }
  }
}

extension MergeVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController( _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
  {
    dismiss(animated: true, completion: nil)

    guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
      mediaType == (kUTTypeMovie as String),
      let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
      else { return }

    let avAsset = AVAsset(url: url)
    var message = ""
    if (vid1 != nil) {
      message = "Video one loaded"
      vid1 = avAsset
    } else {
      message = "Video two loaded"
      vid2 = avAsset
    }
    let alert = UIAlertController(
      title: "Asset Loaded",
      message: message,
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(
      title: "OK",
      style: UIAlertAction.Style.cancel,
      handler: nil))
    present(alert, animated: true, completion: nil)
  }
}

extension MergeVideoViewController: UINavigationControllerDelegate {
}

extension MergeVideoViewController: MPMediaPickerControllerDelegate {
  func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
  {
    dismiss(animated: true)
    {
      let selectedSongs = mediaItemCollection.items
      guard let song = selectedSongs.first else { return }

      let title: String
      let message: String
      if let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
        self.audio = AVAsset(url: url)
        title = "Audio Loaded"
        message = "Audio Loaded"
      } else {
        self.audio = nil
        title = "Asset Not Available"
        message = "Audio Not Loaded"
      }

      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Works", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }

  func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
    dismiss(animated: true, completion: nil)
  }
}

