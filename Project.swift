import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .ImageViewer,
    targets: [
        Target(
            name: .ImageViewer,
            sources: "ImageViewer/Source/**",
            lintConfigPath: nil
        ),
        Target(
            name: .ImageViewerTests,
            product: .unitTests,
            sources: "ImageViewerTests/**",
            lintConfigPath: nil,
            dependencies: [.target(name: .ImageViewer)]
        )
    ],
    additionalFiles: ["README.MD", "ImageViewer.podspec"]
)
