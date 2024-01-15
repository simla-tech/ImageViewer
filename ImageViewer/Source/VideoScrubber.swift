//
//  VideoScrubber.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 08/08/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import AVFoundation
import UIKit

open class VideoScrubber: UIControl {

    let playButton = UIButton.playButton(width: 50, height: 40)
    let pauseButton = UIButton.pauseButton(width: 50, height: 40)
    let replayButton = UIButton.replayButton(width: 50, height: 40)

    let scrubber = Slider.createSlider(320, height: 20, pointerDiameter: 10, barHeight: 2)
    let timeLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 20)))
    var duration: TimeInterval?
    fileprivate var periodicObserver: AnyObject?
    fileprivate var stoppedSlidingTimeStamp = Date()

    /// The attributes dictionary used for the timeLabel
    fileprivate var timeLabelAttributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]

        if let tintColor {
            attributes[NSAttributedString.Key.foregroundColor] = tintColor
        }

        return attributes
    }

    weak var player: AVPlayer? {

        willSet {
            if let player {

                /// KVO
                player.removeObserver(self, forKeyPath: "status")
                player.removeObserver(self, forKeyPath: "rate")

                /// NC
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

                /// TIMER
                if let periodicObserver = self.periodicObserver {

                    player.removeTimeObserver(periodicObserver)
                    self.periodicObserver = nil
                }
            }
        }

        didSet {

            if let player {

                /// KVO
                player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)

                /// NC
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.didEndPlaying),
                    name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                    object: nil
                )

                /// TIMER
                self.periodicObserver = player.addPeriodicTimeObserver(
                    forInterval: CMTime(value: 1, timescale: 1),
                    queue: nil,
                    using: { [weak self] _ in
                        self?.update()
                    }
                ) as AnyObject?

                self.update()
            }
        }
    }

    override init(frame: CGRect) {

        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        self.setup()
    }

    deinit {

        player?.removeObserver(self, forKeyPath: "status")
        player?.removeObserver(self, forKeyPath: "rate")
        scrubber.removeObserver(self, forKeyPath: "isSliding")

        if let periodicObserver = self.periodicObserver {

            player?.removeTimeObserver(periodicObserver)
            self.periodicObserver = nil
        }
    }

    @objc
    func didEndPlaying() {

        self.playButton.isHidden = true
        self.pauseButton.isHidden = true
        self.replayButton.isHidden = false
    }

    func setup() {

        self.tintColor = .white
        self.clipsToBounds = true
        self.pauseButton.isHidden = true
        self.replayButton.isHidden = true

        self.scrubber.minimumValue = 0
        self.scrubber.maximumValue = 1000
        self.scrubber.value = 0

        self.timeLabel.attributedText = NSAttributedString(string: "--:--", attributes: self.timeLabelAttributes)
        self.timeLabel.textAlignment = .center

        self.playButton.addTarget(self, action: #selector(self.play), for: UIControl.Event.touchUpInside)
        self.pauseButton.addTarget(self, action: #selector(self.pause), for: UIControl.Event.touchUpInside)
        self.replayButton.addTarget(self, action: #selector(self.replay), for: UIControl.Event.touchUpInside)
        self.scrubber.addTarget(self, action: #selector(self.updateCurrentTime), for: UIControl.Event.valueChanged)
        self.scrubber.addTarget(
            self,
            action: #selector(self.seekToTime),
            for: [UIControl.Event.touchUpInside, UIControl.Event.touchUpOutside]
        )

        self.addSubviews(self.playButton, self.pauseButton, self.replayButton, self.scrubber, self.timeLabel)

        self.scrubber.addObserver(self, forKeyPath: "isSliding", options: NSKeyValueObservingOptions.new, context: nil)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        self.playButton.center = self.boundsCenter
        self.playButton.frame.origin.x = 0
        self.pauseButton.frame = self.playButton.frame
        self.replayButton.frame = self.playButton.frame

        self.timeLabel.center = self.boundsCenter
        self.timeLabel.frame.origin.x = self.bounds.maxX - self.timeLabel.bounds.width

        self.scrubber.bounds.size.width = self.bounds.width - self.playButton.bounds.width - self.timeLabel.bounds.width
        self.scrubber.bounds.size.height = 20
        self.scrubber.center = self.boundsCenter
        self.scrubber.frame.origin.x = self.playButton.frame.maxX
    }

    // swiftlint:disable:next block_based_kvo
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {

        if keyPath == "isSliding" {

            if self.scrubber.isSliding == false {

                self.stoppedSlidingTimeStamp = Date()
            }
        } else if keyPath == "rate" || keyPath == "status" {

            self.update()
        }
    }

    @objc
    func play() {

        self.player?.play()
    }

    @objc
    func replay() {

        self.player?.seek(to: CMTime(value: 0, timescale: 1))
        self.player?.play()
    }

    @objc
    func pause() {

        self.player?.pause()
    }

    @objc
    func seekToTime() {

        let progress = self.scrubber.value / self.scrubber.maximumValue // naturally will be between 0 to 1

        if let player = self.player, let currentItem = player.currentItem {

            let time = currentItem.duration.seconds * Double(progress)
            player.seek(to: CMTime(seconds: time, preferredTimescale: 1))
        }
    }

    func update() {

        self.updateButtons()
        self.updateDuration()
        self.updateScrubber()
        self.updateCurrentTime()
    }

    func updateButtons() {

        if let player = self.player {

            self.playButton.isHidden = player.isPlaying()
            self.pauseButton.isHidden = !self.playButton.isHidden
            self.replayButton.isHidden = true
        }
    }

    func updateDuration() {

        if let duration = self.player?.currentItem?.duration {

            self.duration = (duration.isNumeric) ? duration.seconds : nil
        }
    }

    func updateScrubber() {

        guard self.scrubber.isSliding == false else { return }

        let timeElapsed = Date().timeIntervalSince(self.stoppedSlidingTimeStamp)
        guard timeElapsed > 1 else {
            return
        }

        if let player = self.player, let duration = self.duration {

            let progress = player.currentTime().seconds / duration

            UIView.animate(withDuration: 0.9, animations: { [weak self] in

                if let strongSelf = self {

                    strongSelf.scrubber.value = Float(progress) * strongSelf.scrubber.maximumValue
                }
            })
        }
    }

    @objc
    func updateCurrentTime() {

        if let duration = self.duration, self.duration != nil {

            let sliderProgress = self.scrubber.value / self.scrubber.maximumValue
            let currentTime = Double(sliderProgress) * duration

            let timeString = self.stringFromTimeInterval(currentTime as TimeInterval)

            self.timeLabel.attributedText = NSAttributedString(string: timeString, attributes: self.timeLabelAttributes)
        } else {
            self.timeLabel.attributedText = NSAttributedString(string: "--:--", attributes: self.timeLabelAttributes)
        }
    }

    func stringFromTimeInterval(_ interval: TimeInterval) -> String {

        let timeInterval = NSInteger(interval)

        let seconds = timeInterval % 60
        let minutes = (timeInterval / 60) % 60
        // let hours = (timeInterval / 3600)

        return NSString(format: "%0.2d:%0.2d", minutes, seconds) as String
        // return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds) as String
    }

    override open func tintColorDidChange() {
        self.timeLabel.attributedText = NSAttributedString(string: "--:--", attributes: self.timeLabelAttributes)

        let playButtonImage = self.playButton.imageView?.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.playButton.imageView?.tintColor = self.tintColor
        self.playButton.setImage(playButtonImage, for: .normal)

        if let playButtonImage,
           let highlightImage = self.image(playButtonImage, with: self.tintColor.shadeDarker()) as UIImage?
        {
            self.playButton.setImage(highlightImage, for: .highlighted)
        }

        let pauseButtonImage = self.pauseButton.imageView?.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.pauseButton.imageView?.tintColor = self.tintColor
        self.pauseButton.setImage(pauseButtonImage, for: .normal)

        if let pauseButtonImage,
           let highlightImage = self.image(pauseButtonImage, with: self.tintColor.shadeDarker()) as UIImage?
        {
            self.pauseButton.setImage(highlightImage, for: .highlighted)
        }

        let replayButtonImage = self.replayButton.imageView?.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.replayButton.imageView?.tintColor = self.tintColor
        self.replayButton.setImage(replayButtonImage, for: .normal)

        if let replayButtonImage,
           let highlightImage = self.image(replayButtonImage, with: self.tintColor.shadeDarker()) as UIImage?
        {
            self.replayButton.setImage(highlightImage, for: .highlighted)
        }
    }

    func image(_ image: UIImage, with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.clip(to: rect, mask: image.cgImage!)
        context?.fill(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let fillImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return fillImage
    }
}
