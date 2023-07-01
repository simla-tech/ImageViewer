//
//  BlurView.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

final class BlurView: UIView {

    var blurPresentDuration: TimeInterval = 0.5
    var blurPresentDelay: TimeInterval = 0

    var colorPresentDuration: TimeInterval = 0.25
    var colorPresentDelay: TimeInterval = 0

    var blurDismissDuration: TimeInterval = 0.1
    var blurDismissDelay: TimeInterval = 0.4

    var colorDismissDuration: TimeInterval = 0.45
    var colorDismissDelay: TimeInterval = 0

    var blurTargetOpacity: CGFloat = 1
    var colorTargetOpacity: CGFloat = 1

    var overlayColor = UIColor.black {
        didSet { self.colorView.backgroundColor = self.overlayColor }
    }

    let blurringViewContainer =
        UIView() // serves as a transparency container for the blurringView as it's not recommended by Apple to apply transparency directly to the UIVisualEffectsView
    let blurringView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    let colorView = UIView()

    convenience init() {

        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.blurringViewContainer.alpha = 0

        self.colorView.backgroundColor = self.overlayColor
        self.colorView.alpha = 0

        self.addSubview(self.blurringViewContainer)
        self.blurringViewContainer.addSubview(self.blurringView)
        self.addSubview(self.colorView)
    }

    @available(iOS, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurringViewContainer.frame = self.bounds
        self.blurringView.frame = self.blurringViewContainer.bounds
        self.colorView.frame = self.bounds
    }

    func present() {

        UIView.animate(
            withDuration: self.blurPresentDuration,
            delay: self.blurPresentDelay,
            options: .curveLinear,
            animations: { [weak self] in

                self?.blurringViewContainer.alpha = self!.blurTargetOpacity

            },
            completion: nil
        )

        UIView.animate(
            withDuration: self.colorPresentDuration,
            delay: self.colorPresentDelay,
            options: .curveLinear,
            animations: { [weak self] in

                self?.colorView.alpha = self!.colorTargetOpacity

            },
            completion: nil
        )
    }

    func dismiss() {

        UIView.animate(
            withDuration: self.blurDismissDuration,
            delay: self.blurDismissDelay,
            options: .curveLinear,
            animations: { [weak self] in

                self?.blurringViewContainer.alpha = 0

            },
            completion: nil
        )

        UIView.animate(
            withDuration: self.colorDismissDuration,
            delay: self.colorDismissDelay,
            options: .curveLinear,
            animations: { [weak self] in

                self?.colorView.alpha = 0

            },
            completion: nil
        )
    }
}
