import Foundation

/// Downloads YouTube videos using yt-dlp CLI tool.
actor YouTubeDownloader {
    enum DownloadError: LocalizedError {
        case ytDlpNotFound
        case invalidURL
        case downloadFailed(String)

        var errorDescription: String? {
            switch self {
            case .ytDlpNotFound:
                "yt-dlp not found. Install with: brew install yt-dlp"
            case .invalidURL:
                "Invalid YouTube URL."
            case .downloadFailed(let msg):
                "Download failed: \(msg)"
            }
        }
    }

    static let shared = YouTubeDownloader()

    private let fileManager = FileManager.default

    /// Validates that a string looks like a YouTube URL.
    nonisolated func isYouTubeURL(_ string: String) -> Bool {
        let patterns = [
            "youtube.com/watch",
            "youtu.be/",
            "youtube.com/shorts/",
            "youtube.com/live/"
        ]
        let lower = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return patterns.contains { lower.contains($0) }
    }

    /// Downloads a YouTube video and returns the local file URL.
    /// Forces H.264 (avc1) codec — AV1 is not supported by macOS AVFoundation.
    func download(url: String, to directory: URL) async throws -> URL {
        guard isYouTubeURL(url) else { throw DownloadError.invalidURL }

        let ytDlpPath = findYtDlp()
        guard let ytDlp = ytDlpPath else { throw DownloadError.ytDlpNotFound }

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let outputTemplate = directory.appendingPathComponent("%(title).50s.%(ext)s").path

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlp)
        // Force H.264 (avc1) — AV1/VP9 won't decode in AVFoundation on most Macs.
        process.arguments = [
            "-f", "bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/best[vcodec^=avc1]/best[ext=mp4]",
            "--merge-output-format", "mp4",
            "--no-playlist",
            "--no-overwrites",
            "-o", outputTemplate,
            "--print", "after_move:filepath",
            url.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw DownloadError.downloadFailed(errMsg)
        }

        let outputPath = String(data: outData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !outputPath.isEmpty, fileManager.fileExists(atPath: outputPath) else {
            // Fallback: find newest mp4 in directory
            if let fallback = newestFile(in: directory, ext: "mp4") {
                return fallback
            }
            throw DownloadError.downloadFailed("Output file not found.")
        }

        return URL(fileURLWithPath: outputPath)
    }

    private func findYtDlp() -> String? {
        let candidates = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        for path in candidates where fileManager.fileExists(atPath: path) {
            return path
        }
        // Try which
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["yt-dlp"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return result.isEmpty ? nil : result
    }

    private func newestFile(in directory: URL, ext: String) -> URL? {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.creationDateKey]
        ) else { return nil }
        return files
            .filter { $0.pathExtension.lowercased() == ext }
            .max { a, b in
                let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return dateA < dateB
            }
    }
}
