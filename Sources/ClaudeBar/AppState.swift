import AppKit
import Combine
import ClaudeBarCore

@MainActor
final class AppState: ObservableObject {
    @Published var snapshot: UsageSnapshot?
    @Published var aggregate = TranscriptScanner.Aggregate()
    @Published var activeProjects: [String] = []
    @Published var lastUpdated: Date?
    @Published var lastError: String?
    @Published var usdKrwRate: Double?

    var onAlerts: (([NotificationPlanner.Alert]) -> Void)?

    private let fetcher: UsageProviding
    private let scanner: TranscriptScanner
    private var planner = NotificationPlanner()

    private var usageTimer: Timer?
    private var localTimer: Timer?
    private var lastSeenModification: Date?
    private var lastAggregationAt = Date.distantPast
    private var lastComputedDayStart = Date.distantPast
    private var rateLimitedUntil: Date?

    var isActive: Bool { !activeProjects.isEmpty }
    // 메뉴바 %와 표정은 5시간 세션 기준 (주간 한도는 팝오버에서 확인,
    // 알림은 둘 중 먼저 소진되는 쪽(displayRemaining) 기준 유지)
    var faceStage: FaceStage { FaceStage(remaining: snapshot?.session.percentRemaining) }

    init(fetcher: UsageProviding = UsageFetcher(), scanner: TranscriptScanner = TranscriptScanner()) {
        self.fetcher = fetcher
        self.scanner = scanner
    }

    func start() {
        Task { await refreshUsage() }
        Task { usdKrwRate = await ExchangeRate.fetchUSDKRW() }
        refreshLocal(force: true)
        scheduleUsageTimer()
        // 5초마다 활동 감지 + 변경 시에만 통계 재집계 (FSEvents 대신 경량 폴링)
        localTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshLocal(force: false) }
        }
    }

    func refreshUsage() async {
        do {
            let snap = try await fetcher.fetch()
            snapshot = snap
            lastUpdated = Date()
            lastError = nil
            let alerts = planner.update(remaining: snap.displayRemaining)
            if !alerts.isEmpty { onAlerts?(alerts) }
        } catch ClaudeBarError.keychainUnavailable {
            snapshot = nil
            lastError = "키체인에서 Claude Code 로그인 정보를 읽지 못했어요. Claude Code에 로그인되어 있는지 확인해주세요."
        } catch ClaudeBarError.apiError(let code) where code == 429 {
            // 사용량 API 요청 제한: 마지막 값 유지하고 5분 백오프
            rateLimitedUntil = Date().addingTimeInterval(300)
            lastError = "요청이 많아 잠시 쉬는 중이에요 — 5분 뒤 자동 재시도"
        } catch {
            // 네트워크/API 오류: 마지막 값 유지
            lastError = "사용량을 가져오지 못했어요 (\(error.localizedDescription))"
        }
        scheduleUsageTimer()
    }

    private func refreshLocal(force: Bool) {
        let projects = scanner.activeProjects()
        if projects != activeProjects { activeProjects = projects }

        let latest = scanner.latestModification()
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let dayRolledOver = startOfDay != lastComputedDayStart
        let fileChanged = latest != lastSeenModification
        let throttleElapsed = Date().timeIntervalSince(lastAggregationAt) >= 30

        if force || dayRolledOver || (fileChanged && throttleElapsed) {
            lastAggregationAt = Date()
            lastComputedDayStart = startOfDay
            lastSeenModification = latest
            let scanner = self.scanner
            Task.detached(priority: .utility) {
                let agg = scanner.aggregate()
                await MainActor.run { self.aggregate = agg }
            }
        }
    }

    private func scheduleUsageTimer() {
        usageTimer?.invalidate()
        let interval: TimeInterval
        if let until = rateLimitedUntil, until > Date() {
            interval = max(until.timeIntervalSinceNow, 60)
        } else {
            // 비공개 사용량 API의 요청 제한이 빡빡해 여유 있게 폴링한다
            interval = isActive ? 60 : 120
        }
        usageTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in await self?.refreshUsage() }
        }
    }
}
