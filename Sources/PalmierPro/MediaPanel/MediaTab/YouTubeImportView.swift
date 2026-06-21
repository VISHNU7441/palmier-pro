import SwiftUI

/// A paste-URL field for importing YouTube videos directly into the media panel.
struct YouTubeImportView: View {
    @Environment(EditorViewModel.self) private var viewModel
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 14))

                TextField("Paste YouTube URL...", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit { startDownload() }
                    .disabled(isDownloading)

                if isDownloading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: startDownload) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    private func startDownload() {
        let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard YouTubeDownloader.shared.isYouTubeURL(url) else {
            errorMessage = "Not a valid YouTube URL."
            return
        }
        errorMessage = nil
        isDownloading = true

        Task {
            await viewModel.importFromYouTube(urlString: url)
            await MainActor.run {
                isDownloading = false
                if viewModel.youtubeImportError != nil {
                    errorMessage = viewModel.youtubeImportError
                } else {
                    urlText = ""
                    errorMessage = nil
                }
            }
        }
    }
}
