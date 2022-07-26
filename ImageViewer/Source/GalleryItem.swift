//
//  GalleryItem.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

public typealias ImageCompletion = (UIImage?) -> Void
public typealias VideoURLCompletion = ((URL?) -> Void)?
public typealias FetchImageBlock = (@escaping ImageCompletion) -> Void
public typealias FetchVideoURLBlock = (VideoURLCompletion) -> Void
public typealias ItemViewControllerBlock = (_ index: Int, _ itemCount: Int, _ fetchImageBlock: FetchImageBlock, _ configuration: GalleryConfiguration, _ isInitialController: Bool) -> UIViewController

public enum GalleryItem {

    case image(fetchImageBlock: FetchImageBlock)
    case video(fetchPreviewImageBlock: FetchImageBlock, fetchVideoURLBlock: FetchVideoURLBlock, videoURL: URL? = nil)
    case custom(fetchImageBlock: FetchImageBlock, itemViewControllerBlock: ItemViewControllerBlock)
}
