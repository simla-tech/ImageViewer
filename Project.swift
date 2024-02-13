import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .ImageViewer,
    targets: [
        .target(
            name: .ImageViewer,
            sources: "ImageViewer/Source/**",
            enableCodeLinting: false
        ),
        .target(
            name: .ImageViewerTests,
            product: .unitTests,
            sources: "ImageViewerTests/**",
            enableCodeLinting: false,
            dependencies: [.target(name: .ImageViewer)]
        )
    ],
    additionalFiles: ["README.MD", "ImageViewer.podspec"]
)
