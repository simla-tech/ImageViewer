import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .ImageViewer,
    targets: [
        Target(
            name: .ImageViewer,
            sources: "ImageViewer/Source/**"
        ),
        Target(
            name: .ImageViewerTests,
            product: .unitTests,
            sources: "ImageViewerTests/**",
            dependencies: [.target(name: .ImageViewer)]
        )
    ],
    additionalFiles: ["README.MD", "ImageViewer.podspec"]
)
