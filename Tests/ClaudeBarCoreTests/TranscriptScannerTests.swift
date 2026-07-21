import XCTest
@testable import ClaudeBarCore

final class TranscriptScannerTests: XCTestCase {
    // now = 2026-07-21T12:00:00Z 기준. 오늘 시작 = 07-21T00:00Z, 주 시작 = 07-19T00:00Z(일요일)로 가정한 UTC 캘린더 테스트.
    let now = Date(timeIntervalSince1970: 1784635200)          // 2026-07-21T12:00:00Z
    let todayStart = Date(timeIntervalSince1970: 1784592000)   // 2026-07-21T00:00:00Z
    let weekStart = Date(timeIntervalSince1970: 1784419200)    // 2026-07-19T00:00:00Z

    func line(id: String, timestamp: String, input: Int = 100, output: Int = 10) -> String {
        #"{"type":"assistant","timestamp":"\#(timestamp)","cwd":"/Users/test/Workspace/demo","message":{"id":"\#(id)","model":"claude-opus-4-8","usage":{"input_tokens":\#(input),"output_tokens":\#(output),"cache_creation_input_tokens":50,"cache_read_input_tokens":200}}}"#
    }

    func testAccumulateCountsTodayAndWeek() {
        var agg = TranscriptScanner.Aggregate()
        var seen = Set<String>()
        let jsonl = [
            line(id: "m1", timestamp: "2026-07-21T10:00:00.000Z"),  // 오늘
            line(id: "m2", timestamp: "2026-07-20T10:00:00.000Z"),  // 이번 주(어제)
            line(id: "m3", timestamp: "2026-07-10T10:00:00.000Z"),  // 지난 주 → 제외
            #"{"type":"user","timestamp":"2026-07-21T10:00:01.000Z"}"#,  // usage 없음 → 무시
            "not json at all",                                            // 파싱 실패 → 무시(크래시 금지)
        ].joined(separator: "\n")

        TranscriptScanner.accumulate(jsonl: jsonl, into: &agg, seenMessageIDs: &seen,
                                     todayStart: todayStart, weekStart: weekStart)

        XCTAssertEqual(agg.today.inputTokens, 100)
        XCTAssertEqual(agg.today.outputTokens, 10)
        XCTAssertEqual(agg.today.cacheWriteTokens, 50)
        XCTAssertEqual(agg.today.cacheReadTokens, 200)
        XCTAssertEqual(agg.week.inputTokens, 200)   // m1 + m2
        XCTAssertGreaterThan(agg.week.costUSD, 0)
    }

    func testAccumulateDedupesByMessageID() {
        var agg = TranscriptScanner.Aggregate()
        var seen = Set<String>()
        let jsonl = [
            line(id: "dup", timestamp: "2026-07-21T10:00:00.000Z"),
            line(id: "dup", timestamp: "2026-07-21T10:00:05.000Z"),  // 재시도 중복
        ].joined(separator: "\n")

        TranscriptScanner.accumulate(jsonl: jsonl, into: &agg, seenMessageIDs: &seen,
                                     todayStart: todayStart, weekStart: weekStart)
        XCTAssertEqual(agg.today.inputTokens, 100)
    }

    func testExtractCwd() {
        let tail = #"{"foo":1}\#n{"type":"assistant","cwd":"/Users/test/Workspace/claude-bar","message":{}}"#
        XCTAssertEqual(TranscriptScanner.extractCwd(fromTail: tail), "/Users/test/Workspace/claude-bar")
        XCTAssertNil(TranscriptScanner.extractCwd(fromTail: "no cwd here"))
    }

    func testTotalTokens() {
        var stats = TokenStats()
        stats.inputTokens = 1; stats.outputTokens = 2
        stats.cacheWriteTokens = 3; stats.cacheReadTokens = 4
        XCTAssertEqual(stats.totalTokens, 10)
    }
}
