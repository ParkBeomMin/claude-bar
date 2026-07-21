import AppKit
import Combine
import ClaudeBarCore

final class StatusItemController {
    let statusItem: NSStatusItem
    private let state: AppState
    private let onClick: () -> Void
    private var cancellable: AnyCancellable?
    private var animationTimer: Timer?
    private var frame = 0

    @MainActor
    init(state: AppState, onClick: @escaping () -> Void) {
        self.state = state
        self.onClick = onClick
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(clicked)
        statusItem.button?.imagePosition = .imageLeft

        cancellable = state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.render() }
            }
        render()
    }

    @objc private func clicked() { onClick() }

    @MainActor
    private func render() {
        let stage = state.faceStage
        statusItem.button?.image = SpriteRenderer.image(grid: CharacterSprites.grid(for: stage, frame: frame))

        let text: String
        if let remaining = state.snapshot?.displayRemaining {
            text = " \(Int(remaining.rounded()))%"
        } else {
            text = " --%"
        }
        statusItem.button?.attributedTitle = NSAttributedString(
            string: text,
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)]
        )
        syncAnimation()
    }

    @MainActor
    private func syncAnimation() {
        if state.isActive, animationTimer == nil {
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.frame = (self.frame + 1) % 2
                    self.statusItem.button?.image = SpriteRenderer.image(
                        grid: CharacterSprites.grid(for: self.state.faceStage, frame: self.frame))
                }
            }
        } else if !state.isActive, animationTimer != nil {
            animationTimer?.invalidate()
            animationTimer = nil
            frame = 0
        }
    }
}
