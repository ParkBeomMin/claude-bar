import Foundation

public struct TokenStats: Equatable {
    public var inputTokens = 0
    public var outputTokens = 0
    public var cacheWriteTokens = 0
    public var cacheReadTokens = 0
    public var costUSD = 0.0

    public var totalTokens: Int { inputTokens + outputTokens + cacheWriteTokens + cacheReadTokens }

    public init() {}

    mutating func add(model: String, input: Int, output: Int, cacheWrite: Int, cacheRead: Int) {
        inputTokens += input
        outputTokens += output
        cacheWriteTokens += cacheWrite
        cacheReadTokens += cacheRead
        costUSD += Pricing.cost(model: model, input: input, output: output,
                                cacheWrite: cacheWrite, cacheRead: cacheRead)
    }
}

public struct TranscriptScanner {
    public struct Aggregate: Equatable {
        public var today = TokenStats()
        public var week = TokenStats()
        public init() {}
    }

    private struct Line: Decodable {
        struct Message: Decodable {
            struct Usage: Decodable {
                let input_tokens: Int?
                let output_tokens: Int?
                let cache_creation_input_tokens: Int?
                let cache_read_input_tokens: Int?
            }
            let id: String?
            let model: String?
            let usage: Usage?
        }
        let type: String?
        let timestamp: String?
        let message: Message?
    }

    public let projectsDirectory: URL

    public init(projectsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/projects")) {
        self.projectsDirectory = projectsDirectory
    }

    // MARK: - 순수 집계 로직 (테스트 대상)

    public static func accumulate(jsonl: String, into agg: inout Aggregate,
                                  seenMessageIDs: inout Set<String>,
                                  todayStart: Date, weekStart: Date) {
        let decoder = JSONDecoder()
        for rawLine in jsonl.split(separator: "\n") {
            // 빠른 사전 필터: assistant 줄이 아니면 디코딩 자체를 건너뜀
            guard rawLine.contains(#""type":"assistant""#) else { continue }
            guard let line = try? decoder.decode(Line.self, from: Data(rawLine.utf8)),
                  line.type == "assistant",
                  let usage = line.message?.usage,
                  let ts = line.timestamp,
                  let date = parseTimestamp(ts),
                  date >= weekStart
            else { continue }

            if let id = line.message?.id {
                guard seenMessageIDs.insert(id).inserted else { continue }
            }

            let model = line.message?.model ?? ""
            let input = usage.input_tokens ?? 0
            let output = usage.output_tokens ?? 0
            let cacheWrite = usage.cache_creation_input_tokens ?? 0
            let cacheRead = usage.cache_read_input_tokens ?? 0

            agg.week.add(model: model, input: input, output: output,
                         cacheWrite: cacheWrite, cacheRead: cacheRead)
            if date >= todayStart {
                agg.today.add(model: model, input: input, output: output,
                              cacheWrite: cacheWrite, cacheRead: cacheRead)
            }
        }
    }

    static func parseTimestamp(_ s: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: s) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
    }

    public static func extractCwd(fromTail tail: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #""cwd":"([^"]+)""#) else { return nil }
        let range = NSRange(tail.startIndex..., in: tail)
        guard let match = regex.matches(in: tail, range: range).last,
              let r = Range(match.range(at: 1), in: tail) else { return nil }
        return String(tail[r])
    }

    // MARK: - 파일시스템 순회

    public func aggregate(now: Date = Date(), calendar: Calendar = .current) -> Aggregate {
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? todayStart
        var agg = Aggregate()
        var seen = Set<String>()

        for file in sessionFiles() {
            guard let mtime = modificationDate(of: file), mtime >= weekStart else { continue }
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            Self.accumulate(jsonl: content, into: &agg, seenMessageIDs: &seen,
                            todayStart: todayStart, weekStart: weekStart)
        }
        return agg
    }

    /// 최근 threshold초 내 수정된 세션 파일이 속한 프로젝트 이름 목록.
    public func activeProjects(now: Date = Date(), threshold: TimeInterval = 30) -> [String] {
        var names = Set<String>()
        for file in sessionFiles() {
            guard let mtime = modificationDate(of: file),
                  now.timeIntervalSince(mtime) < threshold else { continue }
            if let tail = readTail(of: file), let cwd = Self.extractCwd(fromTail: tail) {
                names.insert((cwd as NSString).lastPathComponent)
            }
        }
        return names.sorted()
    }

    /// 가장 최근 세션 파일 수정 시각 — 통계 재계산 트리거 판단용.
    public func latestModification() -> Date? {
        sessionFiles().compactMap(modificationDate(of:)).max()
    }

    private func sessionFiles() -> [URL] {
        guard let projectDirs = try? FileManager.default.contentsOfDirectory(
            at: projectsDirectory, includingPropertiesForKeys: nil) else { return [] }
        return projectDirs.flatMap { dir -> [URL] in
            (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]))?
                .filter { $0.pathExtension == "jsonl" } ?? []
        }
    }

    private func modificationDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    private func readTail(of url: URL, bytes: Int = 8192) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let offset = size > UInt64(bytes) ? size - UInt64(bytes) : 0
        try? handle.seek(toOffset: offset)
        guard let data = try? handle.readToEnd() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
