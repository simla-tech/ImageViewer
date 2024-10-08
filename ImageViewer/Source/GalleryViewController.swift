//
//  GalleryViewController.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import AVFoundation
import UIKit

open class GalleryViewController: UIPageViewController, ItemControllerDelegate {

    // UI
    fileprivate let overlayView = BlurView()
    /// A custom view on the top of the gallery with layout using default (or custom) pinning settings for header.
    open var headerView: UIView?
    /// A custom view at the bottom of the gallery with layout using default (or custom) pinning settings for footer.
    open var footerView: UIView?
    fileprivate var closeButton: UIButton? = UIButton.closeButton()
    fileprivate var seeAllCloseButton: UIButton?
    fileprivate var thumbnailsButton: UIButton? = UIButton.thumbnailsButton()
    fileprivate var deleteButton: UIButton? = UIButton.deleteButton()
    fileprivate let scrubber = VideoScrubber()

    fileprivate weak var initialItemController: ItemController?

    // LOCAL STATE
    // represents the current page index, updated when the root view of the view controller representing the page stops animating inside visible bounds and stays on screen.
    public var currentIndex: Int
    // Picks up the initial value from configuration, if provided. Subsequently also works as local state for the setting.
    fileprivate var decorationViewsHidden = false
    fileprivate var isAnimating = false
    fileprivate var initialPresentationDone = false

    // DATASOURCE/DELEGATE
    fileprivate let itemsDelegate: GalleryItemsDelegate?
    fileprivate let itemsDataSource: GalleryItemsDataSource
    fileprivate let pagingDataSource: GalleryPagingDataSource

    // CONFIGURATION
    fileprivate var spineDividerWidth: Float = 10
    fileprivate var galleryPagingMode = GalleryPagingMode.standard
    fileprivate var headerLayout = HeaderLayout.center(25)
    fileprivate var footerLayout = FooterLayout.center(25)
    fileprivate var closeLayout = ButtonLayout.pinRight(8, 16)
    fileprivate var seeAllCloseLayout = ButtonLayout.pinRight(8, 16)
    fileprivate var thumbnailsLayout = ButtonLayout.pinLeft(8, 16)
    fileprivate var deleteLayout = ButtonLayout.pinRight(8, 66)
    fileprivate var statusBarHidden = true
    fileprivate var overlayAccelerationFactor: CGFloat = 1
    fileprivate var rotationDuration = 0.15
    fileprivate var rotationMode = GalleryRotationMode.always
    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6
    fileprivate var decorationViewsFadeDuration = 0.15
    fileprivate lazy var statusBarHiddenToggled = statusBarHidden

    private var constrained = false

    /// COMPLETION BLOCKS
    /// If set, the block is executed right after the initial launch animations finish.
    open var launchedCompletion: (() -> Void)?
    /// If set, called every time ANY animation stops in the page controller stops and the viewer passes a page index of the page that is currently on screen
    open var landedPageAtIndexCompletion: ((Int) -> Void)?
    /// If set, launched after all animations finish when the close button is pressed.
    open var closedCompletion: (() -> Void)?
    /// If set, launched after all animations finish when the close() method is invoked via public API.
    open var programmaticallyClosedCompletion: (() -> Void)?
    /// If set, launched after all animations finish when the swipe-to-dismiss (applies to all directions and cases) gesture is used.
    open var swipedToDismissCompletion: (() -> Void)?

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public init(
        startIndex: Int,
        itemsDataSource: GalleryItemsDataSource,
        itemsDelegate: GalleryItemsDelegate? = nil,
        displacedViewsDataSource: GalleryDisplacedViewsDataSource? = nil,
        configuration: GalleryConfiguration = []
    ) {

        self.currentIndex = startIndex
        self.itemsDelegate = itemsDelegate
        self.itemsDataSource = itemsDataSource
        var continueNextVideoOnFinish = false

        /// Only those options relevant to the paging GalleryViewController are explicitly handled here, the rest is handled by ItemViewControllers
        for item in configuration {

            switch item {

            case .imageDividerWidth(let width): self.spineDividerWidth = Float(width)
            case .pagingMode(let mode): self.galleryPagingMode = mode
            case .headerViewLayout(let layout): self.headerLayout = layout
            case .footerViewLayout(let layout): self.footerLayout = layout
            case .closeLayout(let layout): self.closeLayout = layout
            case .deleteLayout(let layout): self.deleteLayout = layout
            case .thumbnailsLayout(let layout): self.thumbnailsLayout = layout
            case .statusBarHidden(let hidden): self.statusBarHidden = hidden
            case .hideDecorationViewsOnLaunch(let hidden): self.decorationViewsHidden = hidden
            case .decorationViewsFadeDuration(let duration): self.decorationViewsFadeDuration = duration
            case .rotationDuration(let duration): self.rotationDuration = duration
            case .rotationMode(let mode): self.rotationMode = mode
            case .overlayColor(let color): self.overlayView.overlayColor = color
            case .overlayBlurStyle(let style): self.overlayView.blurringView.effect = UIBlurEffect(style: style)
            case .overlayBlurOpacity(let opacity): self.overlayView.blurTargetOpacity = opacity
            case .overlayColorOpacity(let opacity): self.overlayView.colorTargetOpacity = opacity
            case .blurPresentDuration(let duration): self.overlayView.blurPresentDuration = duration
            case .blurPresentDelay(let delay): self.overlayView.blurPresentDelay = delay
            case .colorPresentDuration(let duration): self.overlayView.colorPresentDuration = duration
            case .colorPresentDelay(let delay): self.overlayView.colorPresentDelay = delay
            case .blurDismissDuration(let duration): self.overlayView.blurDismissDuration = duration
            case .blurDismissDelay(let delay): self.overlayView.blurDismissDelay = delay
            case .colorDismissDuration(let duration): self.overlayView.colorDismissDuration = duration
            case .colorDismissDelay(let delay): self.overlayView.colorDismissDelay = delay
            case .continuePlayVideoOnEnd(let enabled): continueNextVideoOnFinish = enabled
            case .seeAllCloseLayout(let layout): self.seeAllCloseLayout = layout
            case .videoControlsColor(let color): self.scrubber.tintColor = color
            case .closeButtonMode(let buttonMode):

                switch buttonMode {

                case .none: self.closeButton = nil
                case .custom(let button): self.closeButton = button
                case .builtIn: break
                }

            case .seeAllCloseButtonMode(let buttonMode):

                switch buttonMode {

                case .none: self.seeAllCloseButton = nil
                case .custom(let button): self.seeAllCloseButton = button
                case .builtIn: break
                }

            case .thumbnailsButtonMode(let buttonMode):

                switch buttonMode {

                case .none: self.thumbnailsButton = nil
                case .custom(let button): self.thumbnailsButton = button
                case .builtIn: break
                }

            case .deleteButtonMode(let buttonMode):

                switch buttonMode {

                case .none: self.deleteButton = nil
                case .custom(let button): self.deleteButton = button
                case .builtIn: break
                }

            default: break
            }
        }

        self.pagingDataSource = GalleryPagingDataSource(
            itemsDataSource: itemsDataSource,
            displacedViewsDataSource: displacedViewsDataSource,
            scrubber: self.scrubber,
            configuration: configuration
        )

        super.init(
            transitionStyle: UIPageViewController.TransitionStyle.scroll,
            navigationOrientation: UIPageViewController.NavigationOrientation.horizontal,
            options: [UIPageViewController.OptionsKey.interPageSpacing: NSNumber(value: self.spineDividerWidth as Float)]
        )

        self.pagingDataSource.itemControllerDelegate = self

        /// This feels out of place, one would expect even the first presented(paged) item controller to be provided by the paging dataSource but there is nothing we can do as Apple requires the first controller to be set via this "setViewControllers" method.
        let initialController = self.pagingDataSource.createItemController(startIndex, isInitial: true)
        self.setViewControllers(
            [initialController],
            direction: UIPageViewController.NavigationDirection.forward,
            animated: false,
            completion: nil
        )

        if let controller = initialController as? ItemController {

            self.initialItemController = controller
        }

        /// This less known/used presentation style option allows the contents of parent view controller presenting the gallery to "bleed through" the blurView. Otherwise we would see only black color.
        self.modalPresentationStyle = .overFullScreen
        self.dataSource = self.pagingDataSource

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(GalleryViewController.rotate),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        if continueNextVideoOnFinish {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.didEndPlaying),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }

    deinit {

        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func didEndPlaying() {
        self.page(toIndex: self.currentIndex + 1)
    }

    override open var prefersStatusBarHidden: Bool {
        self.statusBarHiddenToggled
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    fileprivate func configureOverlayView() {

        self.overlayView.bounds.size = UIScreen.main.bounds.insetBy(
            dx: -UIScreen.main.bounds.width / 2,
            dy: -UIScreen.main.bounds.height / 2
        ).size
        self.overlayView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)

        self.view.addSubview(self.overlayView)
        self.view.sendSubviewToBack(self.overlayView)
    }

    fileprivate func configureHeaderView() {

        if let header = headerView {
            header.alpha = 0
            self.view.addSubview(header)
        }
    }

    fileprivate func configureFooterView() {

        if let footer = footerView {
            footer.alpha = 0
            self.view.addSubview(footer)
        }
    }

    fileprivate func configureCloseButton() {

        if let closeButton {
            closeButton.addTarget(self, action: #selector(GalleryViewController.closeInteractively), for: .touchUpInside)
            closeButton.alpha = 0
            self.view.addSubview(closeButton)
        }
    }

    fileprivate func configureThumbnailsButton() {

        if let thumbnailsButton {
            thumbnailsButton.addTarget(self, action: #selector(GalleryViewController.showThumbnails), for: .touchUpInside)
            thumbnailsButton.alpha = 0
            self.view.addSubview(thumbnailsButton)
        }
    }

    fileprivate func configureDeleteButton() {

        if let deleteButton {
            deleteButton.addTarget(self, action: #selector(GalleryViewController.deleteItem), for: .touchUpInside)
            deleteButton.alpha = 0
            self.view.addSubview(deleteButton)
        }
    }

    fileprivate func configureScrubber() {

        self.scrubber.alpha = 0
        self.view.addSubview(self.scrubber)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationCapturesStatusBarAppearance = true

        if #available(iOS 11.0, *) {
            if statusBarHidden || UIScreen.hasNotch {
                additionalSafeAreaInsets = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
            }
        }

        self.configureHeaderView()
        self.configureFooterView()
        self.configureCloseButton()
        self.configureThumbnailsButton()
        self.configureDeleteButton()
        self.configureScrubber()

        self.view.clipsToBounds = false
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard self.initialPresentationDone == false else { return }

        /// We have to call this here (not sooner), because it adds the overlay view to the presenting controller and the presentingController property is set only at this moment in the VC lifecycle.
        self.configureOverlayView()

        /// The initial presentation animations and transitions
        self.presentInitially()

        self.initialPresentationDone = true
    }

    fileprivate func presentInitially() {
        self.isAnimating = true

        /// Animates decoration views to the initial state if they are set to be visible on launch. We do not need to do anything if they are set to be hidden because they are already set up as hidden by default. Unhiding them for the launch is part of chosen UX.
        self.initialItemController?.presentItem(alongsideAnimation: { [weak self] in

            self?.overlayView.present()

        }, completion: { [weak self] in

            if let strongSelf = self {

                if strongSelf.decorationViewsHidden == false {

                    strongSelf.animateDecorationViews(visible: true)
                }

                strongSelf.isAnimating = false

                strongSelf.launchedCompletion?()
            }
        })
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.rotationMode == .always, UIApplication.isPortraitOnly {

            let transform = windowRotationTransform()
            let bounds = rotationAdjustedBounds()

            self.view.transform = transform
            self.view.bounds = bounds
        }

        self.overlayView.frame = view.bounds.insetBy(dx: -UIScreen.main.bounds.width * 2, dy: -UIScreen.main.bounds.height * 2)

        self.layoutButton(self.closeButton, layout: self.closeLayout)
        self.layoutButton(self.thumbnailsButton, layout: self.thumbnailsLayout)
        self.layoutButton(self.deleteButton, layout: self.deleteLayout)
        self.layoutHeaderView()
        self.layoutFooterView()
        self.layoutScrubber()
    }

    private var defaultInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: self.statusBarHidden ? 0.0 : 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }

    fileprivate func layoutButton(_ button: UIButton?, layout: ButtonLayout) {

        guard let button else { return }

        switch layout {

        case .pinRight(let marginTop, let marginRight):

            button.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            button.frame.origin.x = self.view.bounds.size.width - marginRight - button.bounds.size.width
            button.frame.origin.y = self.defaultInsets.top + marginTop

        case .pinLeft(let marginTop, let marginLeft):

            button.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            button.frame.origin.x = marginLeft
            button.frame.origin.y = self.defaultInsets.top + marginTop
        }
    }

    fileprivate func layoutHeaderView() {

        guard let header = headerView else { return }

        switch self.headerLayout {

        case .pinCenterTop:

            if !self.constrained {
                header.removeFromSuperview()
                header.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(header)

                var headerSize: CGFloat = 0

                if self.defaultInsets.top > 0 {
                    headerSize = header.frame.size.height + self.defaultInsets.top + 15
                } else {
                    headerSize = header.frame.size.height
                }

                NSLayoutConstraint.activate([
                    header.topAnchor.constraint(equalTo: self.view.topAnchor),
                    header.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    header.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                ])
                header.heightAnchor.constraint(equalToConstant: headerSize).isActive = true

                self.constrained = true
            }

        case .center(let marginTop):

            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            header.center = self.view.boundsCenter
            header.frame.origin.y = self.defaultInsets.top + marginTop

        case .pinBoth(let marginTop, let marginLeft, let marginRight):

            header.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
            header.bounds.size.width = self.view.bounds.width - marginLeft - marginRight
            header.sizeToFit()
            header.frame.origin = CGPoint(x: marginLeft, y: self.defaultInsets.top + marginTop)

        case .pinLeft(let marginTop, let marginLeft):

            header.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            header.frame.origin = CGPoint(x: marginLeft, y: self.defaultInsets.top + marginTop)

        case .pinRight(let marginTop, let marginRight):

            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            header.frame.origin = CGPoint(
                x: self.view.bounds.width - marginRight - header.bounds.width,
                y: self.defaultInsets.top + marginTop
            )
        }
    }

    fileprivate func layoutFooterView() {

        guard let footer = footerView else { return }

        switch self.footerLayout {

        case .center(let marginBottom):

            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            footer.center = self.view.boundsCenter
            footer.frame.origin.y = self.view.bounds.height - footer.bounds.height - marginBottom - self.defaultInsets.bottom

        case .pinBoth(let marginBottom, let marginLeft, let marginRight):

            footer.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            footer.frame.size.width = self.view.bounds.width - marginLeft - marginRight
            footer.sizeToFit()
            footer.frame.origin = CGPoint(
                x: marginLeft,
                y: self.view.bounds.height - footer.bounds.height - marginBottom - self.defaultInsets.bottom
            )

        case .pinLeft(let marginBottom, let marginLeft):

            footer.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            footer.frame.origin = CGPoint(
                x: marginLeft,
                y: self.view.bounds.height - footer.bounds.height - marginBottom - self.defaultInsets.bottom
            )

        case .pinRight(let marginBottom, let marginRight):

            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            footer.frame.origin = CGPoint(
                x: self.view.bounds.width - marginRight - footer.bounds.width,
                y: self.view.bounds.height - footer.bounds.height - marginBottom - self.defaultInsets.bottom
            )
        }
    }

    fileprivate func layoutScrubber() {
        self.scrubber.bounds = CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: self.view.bounds.width - self.scrubberRotationInset(), height: 40)
        )
        self.scrubber.center = self.view.boundsCenter
        self.scrubber.frame.origin.y = (self.footerView?.frame.origin.y ?? self.view.bounds.maxY - 40) - self.scrubber.bounds.height
    }

    /// Accommodate for scrubber's width on landscape screens by narrowing it
    func scrubberRotationInset() -> CGFloat {
        if UIDevice.current.orientation.isLandscape {
            return 100
        } else {
            return 0
        }
    }

    @objc
    fileprivate func deleteItem() {

        self.deleteButton?.isEnabled = false
        view.isUserInteractionEnabled = false

        self.itemsDelegate?.removeGalleryItem(at: self.currentIndex)
        self.removePage(atIndex: self.currentIndex) { [weak self] in
            self?.deleteButton?.isEnabled = true
            self?.view.isUserInteractionEnabled = true
        }
    }

    // ThumbnailsimageBlock

    @objc
    fileprivate func showThumbnails() {

        let thumbnailsController = ThumbnailsViewController(itemsDataSource: self.itemsDataSource)

        if let closeButton = seeAllCloseButton {
            thumbnailsController.closeButton = closeButton
            thumbnailsController.closeLayout = self.seeAllCloseLayout
        } else if let closeButton {
            let seeAllCloseButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: closeButton.bounds.size))
            seeAllCloseButton.setImage(closeButton.image(for: UIControl.State()), for: UIControl.State())
            seeAllCloseButton.setImage(closeButton.image(for: .highlighted), for: .highlighted)
            thumbnailsController.closeButton = seeAllCloseButton
            thumbnailsController.closeLayout = self.closeLayout
        }

        thumbnailsController.onItemSelected = { [weak self] index in

            self?.page(toIndex: index)
        }

        present(thumbnailsController, animated: true, completion: nil)
    }

    open func page(toIndex index: Int) {

        guard self.currentIndex != index, index >= 0, index < self.itemsDataSource.itemCount() else { return }

        let imageViewController = self.pagingDataSource.createItemController(index)
        let direction: UIPageViewController.NavigationDirection = index > self.currentIndex ? .forward : .reverse

        // workaround to make UIPageViewController happy
        if direction == .forward {
            let previousVC = self.pagingDataSource.createItemController(index - 1)
            setViewControllers([previousVC], direction: direction, animated: true, completion: { _ in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        } else {
            let nextVC = self.pagingDataSource.createItemController(index + 1)
            setViewControllers([nextVC], direction: direction, animated: true, completion: { _ in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        }
    }

    func removePage(atIndex index: Int, completion: @escaping () -> Void) {

        // If removing last item, go back, otherwise, go forward

        let direction: UIPageViewController.NavigationDirection = index < self.itemsDataSource.itemCount() ? .forward : .reverse

        let newIndex = direction == .forward ? index : index - 1

        if newIndex < 0 { self.close(); return }

        let vc = self.pagingDataSource.createItemController(newIndex)
        setViewControllers([vc], direction: direction, animated: true) { _ in completion() }
    }

    open func reload(atIndex index: Int) {

        guard index >= 0, index < self.itemsDataSource.itemCount() else { return }

        guard let firstVC = viewControllers?.first, let itemController = firstVC as? ItemController else { return }

        itemController.fetchImage()
    }

    // MARK: - Animations

    @objc
    fileprivate func rotate() {

        /// If the app supports rotation on global level, we don't need to rotate here manually because the rotation
        /// of key Window will rotate all app's content with it via affine transform and from the perspective of the
        /// gallery it is just a simple relayout. Allowing access to remaining code only makes sense if the app is
        /// portrait only but we still want to support rotation inside the gallery.
        guard UIApplication.isPortraitOnly else { return }

        guard UIDevice.current.orientation.isFlat == false,
              self.isAnimating == false else { return }

        self.isAnimating = true

        UIView.animate(
            withDuration: self.rotationDuration,
            delay: 0,
            options: UIView.AnimationOptions.curveLinear,
            animations: { [weak self] () in

                self?.view.transform = windowRotationTransform()
                self?.view.bounds = rotationAdjustedBounds()
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()

            },
            completion: { [weak self] _ in
                self?.isAnimating = false
            }
        )
    }

    /// Invoked when closed programmatically
    open func close() {
        self.closeDecorationViews(self.programmaticallyClosedCompletion)
        setNeedsStatusBarAppearanceUpdate()
    }

    /// Invoked when closed via close button
    @objc
    public func closeInteractively() {
        self.closeDecorationViews(self.closedCompletion)
        setNeedsStatusBarAppearanceUpdate()
    }

    fileprivate func closeDecorationViews(_ completion: (() -> Void)?) {

        guard self.isAnimating == false else { return }
        self.isAnimating = true

        if let itemController = self.viewControllers?.first as? ItemController {

            itemController.closeDecorationViews(self.decorationViewsFadeDuration)
        }

        UIView.animate(withDuration: self.decorationViewsFadeDuration, animations: { [weak self] in

            self?.headerView?.alpha = 0.0
            self?.footerView?.alpha = 0.0
            self?.closeButton?.alpha = 0.0
            self?.thumbnailsButton?.alpha = 0.0
            self?.deleteButton?.alpha = 0.0
            self?.scrubber.alpha = 0.0

        }, completion: { [weak self] _ in

            if let strongSelf = self,
               let itemController = strongSelf.viewControllers?.first as? ItemController
            {

                itemController.dismissItem(alongsideAnimation: {

                    strongSelf.overlayView.dismiss()

                }, completion: { [weak self] in

                    self?.isAnimating = true
                    self?.closeGallery(false, completion: completion)
                })
            }
        })
    }

    func closeGallery(_ animated: Bool, completion: (() -> Void)?) {

        self.overlayView.removeFromSuperview()

        self.modalTransitionStyle = .crossDissolve

        self.dismiss(animated: animated) {
            UIApplication.applicationWindow?.windowLevel = UIWindow.Level.normal
            completion?()
        }
    }

    fileprivate func animateDecorationViews(visible: Bool) {

        let targetAlpha: CGFloat = visible ? 1 : 0

        UIView.animate(withDuration: self.decorationViewsFadeDuration, animations: { [weak self] in

            self?.headerView?.alpha = targetAlpha
            self?.footerView?.alpha = targetAlpha
            self?.closeButton?.alpha = targetAlpha
            self?.thumbnailsButton?.alpha = targetAlpha
            self?.deleteButton?.alpha = targetAlpha

            if self?.viewControllers?.first is VideoViewController {
                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    self?.scrubber.alpha = targetAlpha
                })
            }

            self?.setNeedsStatusBarAppearanceUpdate()

        })
    }

    public func itemControllerWillAppear(_ controller: ItemController) {

        if let videoController = controller as? VideoViewController {

            self.scrubber.player = videoController.player
        }
    }

    public func itemControllerWillDisappear(_ controller: ItemController) {

        if controller is VideoViewController {

            self.scrubber.player = nil

            UIView.animate(withDuration: 0.3, animations: { [weak self] in

                self?.scrubber.alpha = 0
            })
        }
    }

    public func itemControllerDidAppear(_ controller: ItemController) {

        self.currentIndex = controller.index
        self.landedPageAtIndexCompletion?(self.currentIndex)
        self.headerView?.sizeToFit()
        self.footerView?.sizeToFit()

        if let videoController = controller as? VideoViewController {
            self.scrubber.player = videoController.player
            if self.scrubber.alpha == 0, self.decorationViewsHidden == false {

                UIView.animate(withDuration: 0.3, animations: { [weak self] in

                    self?.scrubber.alpha = 1
                })
            }
        }
    }

    open func itemControllerDidSingleTap(_ controller: ItemController) {
        if !self.statusBarHidden {
            self.statusBarHiddenToggled.toggle()
        }
        self.decorationViewsHidden.flip()
        self.animateDecorationViews(visible: !self.decorationViewsHidden)
    }

    open func itemControllerDidLongPress(_ controller: ItemController, in item: ItemView) {
        switch (controller, item) {

        case (_ as ImageViewController, let item as UIImageView):
            guard let image = item.image else { return }
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activityVC, animated: true)

        case (_ as VideoViewController, let item as VideoView):
            guard let videoUrl = ((item.player?.currentItem?.asset) as? AVURLAsset)?.url else { return }
            let activityVC = UIActivityViewController(activityItems: [videoUrl], applicationActivities: nil)
            self.present(activityVC, animated: true)

        default: return
        }
    }

    public func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat) {

        if self.decorationViewsHidden == false {

            let alpha = 1 - distance * self.swipeToDismissFadeOutAccelerationFactor

            self.closeButton?.alpha = alpha
            self.thumbnailsButton?.alpha = alpha
            self.deleteButton?.alpha = alpha
            self.headerView?.alpha = alpha
            self.footerView?.alpha = alpha

            if controller is VideoViewController {
                self.scrubber.alpha = alpha
            }
        }

        self.overlayView.blurringView.alpha = 1 - distance
        self.overlayView.colorView.alpha = 1 - distance
    }

    public func itemControllerDidFinishSwipeToDismissSuccessfully() {

        self.swipedToDismissCompletion?()
        self.overlayView.removeFromSuperview()
        self.dismiss(animated: false, completion: nil)
    }
}
