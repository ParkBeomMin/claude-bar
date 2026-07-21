import AppKit
import ClaudeBarCore

enum SpriteRenderer {
    static let palette: [Character: NSColor] = [
        "o": NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1),   // Claude 주황 (#D97757)
        "d": NSColor(srgbRed: 0.64, green: 0.32, blue: 0.20, alpha: 1),   // 진한 주황 외곽선 (#A35233)
        "k": NSColor.black,
        "w": NSColor.white,
    ]

    static func image(grid: [String]) -> NSImage {
        let n = 16
        let image = NSImage(size: NSSize(width: n, height: n), flipped: true) { _ in
            NSGraphicsContext.current?.shouldAntialias = false
            for (y, row) in grid.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    color.setFill()
                    NSRect(x: x, y: y, width: 1, height: 1).fill()
                }
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
