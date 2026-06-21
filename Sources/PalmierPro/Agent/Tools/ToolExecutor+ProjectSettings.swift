import Foundation

/// MCP tool: set_project_settings — change resolution, fps, etc.
extension ToolExecutor {
    func setProjectSettings(_ editor: EditorViewModel, _ args: [String: Any]) throws -> ToolResult {
        var changed: [String] = []

        if let width = args.int("width"), let height = args.int("height") {
            guard width > 0, width <= 7680, height > 0, height <= 7680 else {
                throw ToolError("width/height must be 1–7680.")
            }
            editor.timeline.width = width
            editor.timeline.height = height
            changed.append("resolution \(width)x\(height)")
        }

        if let fps = args.int("fps") {
            guard [24, 25, 30, 50, 60].contains(fps) else {
                throw ToolError("fps must be one of: 24, 25, 30, 50, 60.")
            }
            editor.timeline.fps = fps
            changed.append("fps \(fps)")
        }

        guard !changed.isEmpty else {
            throw ToolError("No settings to change. Pass width+height and/or fps.")
        }

        editor.timeline.settingsConfigured = true
        editor.notifyTimelineChanged()
        editor.undoManager?.setActionName("Set Project Settings (Agent)")

        return .ok("Updated project settings: \(changed.joined(separator: ", ")). Canvas is now \(editor.timeline.width)x\(editor.timeline.height) @ \(editor.timeline.fps)fps.")
    }
}
