import Foundation

/// YouTube import integration — downloads via yt-dlp and adds to media library.
extension EditorViewModel {
    /// Error message from the last YouTube import attempt, cleared on success.
    @MainActor
    func importFromYouTube(urlString: String) async {
        youtubeImportError = nil

        let downloadDir: URL
        if let projectURL {
            downloadDir = projectURL
                .appendingPathComponent(Project.mediaDirectoryName, isDirectory: true)
                .appendingPathComponent("YouTube", isDirectory: true)
        } else {
            downloadDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("PalmierPro-YouTube", isDirectory: true)
        }

        do {
            let fileURL = try await YouTubeDownloader.shared.download(
                url: urlString,
                to: downloadDir
            )
            addMediaAsset(from: fileURL, folderId: mediaPanelCurrentFolderId)
        } catch {
            youtubeImportError = error.localizedDescription
        }
    }
}