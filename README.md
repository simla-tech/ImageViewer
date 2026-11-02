![Tests](https://github.com/jocmp/ImageViewer/actions/workflows/CI.yml/badge.svg)

![Single image view](https://github.com/jocmp/ImageViewer/blob/main/Documentation/single.gif)

![Gallery](https://github.com/jocmp/ImageViewer/blob/main/Documentation/gallery.gif)

For the latest changes see the [CHANGELOG](CHANGELOG.md)

## Install

### SwiftPM

Just add the repository URL in Xcode.


## Sample Usage

For a detailed example, see the [Example](https://github.com/jocmp/ImageViewer/tree/main/Example)

```swift
// Show the ImageViewer with the first item
self.presentImageGallery(GalleryViewController(startIndex: 0, itemsDataSource: self))

// The GalleryItemsDataSource provides the items to show
extension ViewController: GalleryItemsDataSource {
    func itemCount() -> Int {
        return items.count
    }

    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return items[index].galleryItem
    }
}
```
