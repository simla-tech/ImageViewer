//
//  ThumbnailsViewController.swift
//  ImageViewer
//
//  Created by Zeno Foltin on 07/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

final class ThumbnailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UINavigationBarDelegate {

    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var isAnimating = false
    fileprivate let rotationAnimationDuration = 0.2

    var onItemSelected: ((Int) -> Void)?
    let layout = UICollectionViewFlowLayout()
    weak var itemsDataSource: GalleryItemsDataSource!
    var closeButton: UIButton?
    var closeLayout: ButtonLayout?

    required init(itemsDataSource: GalleryItemsDataSource) {
        self.itemsDataSource = itemsDataSource

        super.init(collectionViewLayout: self.layout)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.rotate),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func rotate() {
        guard UIApplication.isPortraitOnly else { return }

        guard UIDevice.current.orientation.isFlat == false,
              self.isAnimating == false else { return }

        self.isAnimating = true

        UIView.animate(
            withDuration: self.rotationAnimationDuration,
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

    override func viewDidLoad() {
        super.viewDidLoad()

        let screenWidth = self.view.frame.width
        self.layout.sectionInset = UIEdgeInsets(top: 50, left: 8, bottom: 8, right: 8)
        self.layout.itemSize = CGSize(width: screenWidth / 3 - 8, height: screenWidth / 3 - 8)
        self.layout.minimumInteritemSpacing = 4
        self.layout.minimumLineSpacing = 4

        self.collectionView?.register(ThumbnailCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)

        self.addCloseButton()
    }

    fileprivate func addCloseButton() {
        guard let closeButton, let closeLayout else { return }

        switch closeLayout {
        case .pinRight(let marginTop, let marginRight):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            closeButton.frame.origin.x = self.view.bounds.size.width - marginRight - closeButton.bounds.size.width
            closeButton.frame.origin.y = marginTop
        case .pinLeft(let marginTop, let marginLeft):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            closeButton.frame.origin.x = marginLeft
            closeButton.frame.origin.y = marginTop
        }

        closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)

        self.view.addSubview(closeButton)
    }

    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.itemsDataSource.itemCount()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as! ThumbnailCell

        let item = self.itemsDataSource.provideGalleryItem((indexPath as NSIndexPath).row)

        switch item {

        case .image(let fetchImageBlock):

            fetchImageBlock { image in

                if let image {

                    cell.imageView.image = image
                }
            }

        case .video(let fetchImageBlock, _, _):

            fetchImageBlock { image in

                if let image {

                    cell.imageView.image = image
                }
            }

        case .custom(let fetchImageBlock, _):

            fetchImageBlock { image in

                if let image {

                    cell.imageView.image = image
                }
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.onItemSelected?((indexPath as NSIndexPath).row)
        self.close()
    }
}
