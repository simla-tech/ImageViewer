//
//  ImageViewController.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/08/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import AVFoundation
import UIKit

extension VideoView: ItemView { }

final class VideoViewController: ItemBaseController<VideoView> {

    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6

    private var fetchVideoURLBlock: FetchVideoURLBlock

    var videoURL: URL?
    var player: AVPlayer?
    unowned let scrubber: VideoScrubber

    let fullHDScreenSizeLandscape = CGSize(width: 1920, height: 1080)
    let fullHDScreenSizePortrait = CGSize(width: 1080, height: 1920)
    let embeddedPlayButton = UIButton.circlePlayButton(70)

    private var autoPlayStarted = false
    private var autoPlayEnabled = false

    init(
        index: Int,
        itemCount: Int,
        fetchImageBlock: @escaping FetchImageBlock,
        fetchVideoURLBlock: @escaping FetchVideoURLBlock,
        videoURL: URL? = nil,
        scrubber: VideoScrubber,
        configuration: GalleryConfiguration,
        isInitialController: Bool = false
    ) {

        self.videoURL = videoURL
        if let videoURL = self.videoURL {
            self.player = AVPlayer(url: videoURL)
        }

        self.fetchVideoURLBlock = fetchVideoURLBlock

        self.scrubber = scrubber

        // Only those options relevant to the paging VideoViewController are explicitly handled here, the rest is handled by ItemViewControllers
        for item in configuration {

            switch item {

            case .videoAutoPlay(let enabled):
                self.autoPlayEnabled = enabled

            default: break
            }
        }

        super.init(
            index: index,
            itemCount: itemCount,
            fetchImageBlock: fetchImageBlock,
            configuration: configuration,
            isInitialController: isInitialController
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchVideoURL()

        if isInitialController == true { self.embeddedPlayButton.alpha = 0 }

        self.embeddedPlayButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        self.view.addSubview(self.embeddedPlayButton)
        self.embeddedPlayButton.center = self.view.boundsCenter

        self.embeddedPlayButton.addTarget(self, action: #selector(self.playVideoInitially), for: UIControl.Event.touchUpInside)

        self.itemView.contentMode = .scaleAspectFill
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.player?.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let isLandscape = itemView.bounds.width >= itemView.bounds.height
        itemView.bounds.size = aspectFitSize(
            forContentOfSize: isLandscape ? self.fullHDScreenSizeLandscape : self.fullHDScreenSizePortrait,
            inBounds: self.scrollView.bounds.size
        )
        itemView.center = scrollView.boundsCenter
    }

    public func fetchVideoURL() {

        self.activityIndicatorView.startAnimating()

        self.fetchVideoURLBlock { [weak self] videoURL in

            guard let self else { return }

            if let videoURL {

                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.player = AVPlayer(url: videoURL)
                    self.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                    self.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
                    UIApplication.shared.beginReceivingRemoteControlEvents()

                    self.itemView.player = self.player
                    self.scrubber.player = self.player
                    self.performAutoPlay()
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    deinit {
        self.player?.removeObserver(self, forKeyPath: "status")
        self.player?.removeObserver(self, forKeyPath: "rate")

        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    @objc
    func playVideoInitially() {

        self.player?.play()

        UIView.animate(withDuration: 0.25, animations: { [weak self] in

            self?.embeddedPlayButton.alpha = 0

        }, completion: { [weak self] _ in

            self?.embeddedPlayButton.isHidden = true
        })
    }

    override func closeDecorationViews(_ duration: TimeInterval) {

        UIView.animate(withDuration: duration, animations: { [weak self] in

            self?.embeddedPlayButton.alpha = 0
            self?.itemView.previewImageView.alpha = 1
        })
    }

    override func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void) {

        let circleButtonAnimation = {

            UIView.animate(withDuration: 0.15, animations: { [weak self] in
                self?.embeddedPlayButton.alpha = 1
            })
        }

        super.presentItem(alongsideAnimation: alongsideAnimation) {

            circleButtonAnimation()
            completion()
        }
    }

    override func displacementTargetSize(forSize size: CGSize) -> CGSize {

        let isLandscape = itemView.bounds.width >= itemView.bounds.height
        return aspectFitSize(
            forContentOfSize: isLandscape ? self.fullHDScreenSizeLandscape : self.fullHDScreenSizePortrait,
            inBounds: rotationAdjustedBounds().size
        )
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {

        if keyPath == "rate" || keyPath == "status" {

            self.fadeOutEmbeddedPlayButton()
        } else if keyPath == "contentOffset" {

            self.handleSwipeToDismissTransition()
        }

        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }

    func handleSwipeToDismissTransition() {
        guard swipingToDismiss != nil else { return }
        self.embeddedPlayButton.center.y = view.center.y - scrollView.contentOffset.y
    }

    func fadeOutEmbeddedPlayButton() {
        guard let player else {
            return
        }
        if player.isPlaying(), self.embeddedPlayButton.alpha != 0 {

            UIView.animate(withDuration: 0.3, animations: { [weak self] in

                self?.embeddedPlayButton.alpha = 0
            })
        }
    }

    override func remoteControlReceived(with event: UIEvent?) {

        guard let player = self.player else {
            return
        }

        if let event {

            if event.type == UIEvent.EventType.remoteControl {

                switch event.subtype {

                case .remoteControlTogglePlayPause:

                    if player.isPlaying() {

                        player.pause()
                    } else {

                        player.play()
                    }

                case .remoteControlPause:

                    player.pause()

                case .remoteControlPlay:

                    player.play()

                case .remoteControlPreviousTrack:

                    player.pause()
                    player.seek(to: CMTime(value: 0, timescale: 1))
                    player.play()

                default:

                    break
                }
            }
        }
    }

    private func performAutoPlay() {
        guard self.autoPlayEnabled else { return }
        guard self.autoPlayStarted == false else { return }

        self.autoPlayStarted = true
        self.embeddedPlayButton.isHidden = true
        self.scrubber.play()
    }
}
