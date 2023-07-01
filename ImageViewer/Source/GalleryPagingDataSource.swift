//
//  GalleryPagingDataSource.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 15/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

final class GalleryPagingDataSource: NSObject, UIPageViewControllerDataSource {

    weak var itemControllerDelegate: ItemControllerDelegate?
    fileprivate weak var itemsDataSource: GalleryItemsDataSource?
    fileprivate weak var displacedViewsDataSource: GalleryDisplacedViewsDataSource?

    fileprivate let configuration: GalleryConfiguration
    fileprivate var pagingMode = GalleryPagingMode.standard
    fileprivate var itemCount: Int { self.itemsDataSource?.itemCount() ?? 0 }
    fileprivate unowned var scrubber: VideoScrubber

    init(
        itemsDataSource: GalleryItemsDataSource,
        displacedViewsDataSource: GalleryDisplacedViewsDataSource?,
        scrubber: VideoScrubber,
        configuration: GalleryConfiguration
    ) {

        self.itemsDataSource = itemsDataSource
        self.displacedViewsDataSource = displacedViewsDataSource
        self.scrubber = scrubber
        self.configuration = configuration

        if itemsDataSource.itemCount() > 1 { // Potential carousel mode present in configuration only makes sense for more than 1 item

            for item in configuration {

                switch item {

                case .pagingMode(let mode): self.pagingMode = mode
                default: break
                }
            }
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {

        guard let currentController = viewController as? ItemController else { return nil }
        let previousIndex = (currentController.index == 0) ? self.itemCount - 1 : currentController.index - 1

        switch self.pagingMode {

        case .standard:
            return (currentController.index > 0) ? self.createItemController(previousIndex) : nil

        case .carousel:
            return self.createItemController(previousIndex)
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {

        guard let currentController = viewController as? ItemController else { return nil }
        let nextIndex = (currentController.index == self.itemCount - 1) ? 0 : currentController.index + 1

        switch self.pagingMode {

        case .standard:
            return (currentController.index < self.itemCount - 1) ? self.createItemController(nextIndex) : nil

        case .carousel:
            return self.createItemController(nextIndex)
        }
    }

    func createItemController(_ itemIndex: Int, isInitial: Bool = false) -> UIViewController {

        guard let itemsDataSource else { return UIViewController() }

        let item = itemsDataSource.provideGalleryItem(itemIndex)

        switch item {

        case .image(let fetchImageBlock):

            let imageController = ImageViewController(
                index: itemIndex,
                itemCount: itemsDataSource.itemCount(),
                fetchImageBlock: fetchImageBlock,
                configuration: self.configuration,
                isInitialController: isInitial
            )
            imageController.delegate = self.itemControllerDelegate
            imageController.displacedViewsDataSource = self.displacedViewsDataSource

            return imageController

        case .video(let fetchImageBlock, let fetchVideoURLBlock, let videoURL):

            let videoController = VideoViewController(
                index: itemIndex,
                itemCount: itemsDataSource.itemCount(),
                fetchImageBlock: fetchImageBlock,
                fetchVideoURLBlock: fetchVideoURLBlock,
                videoURL: videoURL,
                scrubber: self.scrubber,
                configuration: self.configuration,
                isInitialController: isInitial
            )

            videoController.delegate = self.itemControllerDelegate
            videoController.displacedViewsDataSource = self.displacedViewsDataSource

            return videoController

        case .custom(let fetchImageBlock, let itemViewControllerBlock):

            guard let itemController = itemViewControllerBlock(
                itemIndex,
                itemsDataSource.itemCount(),
                fetchImageBlock,
                configuration,
                isInitial
            ) as? ItemController, let vc = itemController as? UIViewController else { return UIViewController() }

            itemController.delegate = self.itemControllerDelegate
            itemController.displacedViewsDataSource = self.displacedViewsDataSource

            return vc
        }
    }
}
