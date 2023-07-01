import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .ImageViewer,
    targets: [
        Target(
            name: .ImageViewer,
            sources: "ImageViewer/Source/**",
            enableCodeLinting: false
        ),
        Target(
            name: .ImageViewerTests,
            product: .unitTests,
            sources: "ImageViewerTests/**",
            enableCodeLinting: false,
            dependencies: [.target(name: .ImageViewer)]
        )
    ],
    additionalFiles: ["README.MD", "ImageViewer.podspec"]
)
