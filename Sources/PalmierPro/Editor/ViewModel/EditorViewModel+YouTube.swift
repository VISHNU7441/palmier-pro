import Foundation

/// YouTube import integration — downloads via yt-dlp and adds to media library.
extension EditorViewModel {
    /// Downloads a YouTube video and imports it into the media library.
    /// Returns nil on success, or an error message on failure.
    @MainActor
    func importFromYouTube(urlString: String) async -> String? {
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
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
