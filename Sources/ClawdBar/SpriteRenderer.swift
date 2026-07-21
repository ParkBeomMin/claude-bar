import AppKit
import ClawdBarCore

enum SpriteRenderer {
    static let palette: [Character: NSColor] = [
        "o": NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1),   // Claude 주황 (#D97757)
        "d": NSColor(srgbRed: 0.45, green: 0.22, blue: 0.14, alpha: 1),   // 진한 외곽선
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
