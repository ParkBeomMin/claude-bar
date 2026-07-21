import SwiftUI
import ClawdBarCore

struct GaugeBar: View {
    let remaining: Double  // 0...100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule().fill(color)
                    .frame(width: max(6, geo.size.width * remaining / 100))
            }
        }
        .frame(height: 8)
    }

    private var color: Color {
        if remaining > 40 { return .green }
        if remaining > 20 { return .orange }
        return .red
    }
}

struct PopoverView: View {
    @ObservedObject var state: AppState
    @AppStorage("notify20") private var notify20 = true
    @AppStorage("notify5") private var notify5 = true
    @AppStorage("launchAtLogin") private var launchAtLoginEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            limitsSection
            Divider()
            statsSection
            if !state.activeProjects.isEmpty {
                Divider()
                activitySection
            }
            Divider()
            settingsSection
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            if LaunchAtLogin.isAvailable {
                launchAtLoginEnabled = LaunchAtLogin.isEnabled
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: SpriteRenderer.image(grid: CharacterSprites.grid(for: state.faceStage, frame: 0)))
                .resizable()
                .interpolation(.none)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusLine).font(.headline)
                if let error = state.lastError {
                    Text(error).font(.caption).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let updated = state.lastUpdated {
                    Text("마지막 갱신 \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private var statusLine: String {
        switch state.faceStage {
        case .calm: return "여유로워요~"
        case .smile: return "잘 쓰고 있어요!"
        case .worried: return "슬슬 아껴 쓸까요?"
        case .struggling: return "한도가 얼마 안 남았어요…"
        case .knockedOut: return "기절… 퇴근하세요!"
        case .unknown: return "사용량을 알 수 없어요"
        }
    }

    private var limitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            gaugeRow(title: "5시간 세션",
                     window: state.snapshot?.session)
            gaugeRow(title: "주간 한도",
                     window: state.snapshot?.weekly)
        }
    }

    private func gaugeRow(title: String, window: UsageWindow?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.caption).foregroundColor(.secondary)
                Spacer()
                if let window {
                    Text("\(Int(window.percentRemaining.rounded()))% 남음 · \(Formatters.timeUntil(window.resetsAt))")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("—").font(.caption).foregroundColor(.secondary)
                }
            }
            GaugeBar(remaining: window?.percentRemaining ?? 0)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("토큰 사용량 (API 환산)").font(.caption).foregroundColor(.secondary)
            statsRow(label: "오늘", stats: state.aggregate.today)
            statsRow(label: "이번 주", stats: state.aggregate.week)
        }
    }

    private func statsRow(label: String, stats: TokenStats) -> some View {
        HStack {
            Text(label).frame(width: 50, alignment: .leading)
            Text("\(Formatters.tokens(stats.totalTokens)) tokens")
            Spacer()
            Text(Formatters.usd(stats.costUSD)).foregroundColor(.secondary)
        }
        .font(.system(.caption, design: .monospaced))
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("작업 중").font(.caption).foregroundColor(.secondary)
            ForEach(state.activeProjects, id: \.self) { name in
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text(name).font(.caption)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("잔여 20% 알림", isOn: $notify20).font(.caption)
            Toggle("잔여 5% 알림", isOn: $notify5).font(.caption)
            Toggle("로그인 시 자동 시작", isOn: $launchAtLoginEnabled)
                .font(.caption)
                .disabled(!LaunchAtLogin.isAvailable)
                .onChange(of: launchAtLoginEnabled) { newValue in
                    do {
                        try LaunchAtLogin.set(newValue)
                    } catch {
                        launchAtLoginEnabled = LaunchAtLogin.isEnabled
                    }
                }
            HStack {
                Button("새로고침") { Task { await state.refreshUsage() } }
                Spacer()
                Button("종료") { NSApplication.shared.terminate(nil) }
            }
            .font(.caption)
        }
    }
}
