import Foundation

public enum CharacterSprites {
    /// Clawd(Claude Code 마스코트) 스타일 몸통 베이스 (16×16).
    /// 각진 주황 몸통 + 위로 든 양쪽 집게 + 아래 짧은 다리.
    /// '.'투명 'o'주황 'd'진한 주황 외곽선
    static let body: [String] = [
        "................",  // 0
        "..dd........dd..",  // 1  집게 끝
        ".dood......dood.",  // 2  집게
        ".dood......dood.",  // 3
        "..dd.dddddd.dd..",  // 4  집게 아래 + 몸통 윗변
        "...ddoooooodd...",  // 5
        "..dooooooooood..",  // 6
        ".dooooooooooood.",  // 7
        ".dooooooooooood.",  // 8
        ".dooooooooooood.",  // 9
        ".dooooooooooood.",  // 10
        ".dooooooooooood.",  // 11
        "..dooooooooood..",  // 12
        "...dddddddddd...",  // 13
        "...dd..dd..dd...",  // 14 다리 3개
        "................",  // 15
    ]

    /// 표정 패치: (row, col, char). Clawd 특유의 세로 네모 눈이 기본.
    static func facePatches(for stage: FaceStage) -> [(Int, Int, Character)] {
        // 2×2 네모 눈 (Clawd 기본 눈)
        let blockEyes: [(Int, Int, Character)] = [
            (7, 4, "k"), (7, 5, "k"), (8, 4, "k"), (8, 5, "k"),
            (7, 10, "k"), (7, 11, "k"), (8, 10, "k"), (8, 11, "k"),
        ]
        switch stage {
        case .calm:  // 네모 눈만 (Clawd 기본 표정)
            return blockEyes
        case .smile:  // 네모 눈 + 웃는 입
            return blockEyes + [(10, 6, "k"), (11, 7, "k"), (11, 8, "k"), (10, 9, "k")]
        case .worried:  // 네모 눈 + 벌린 입 + 땀
            return blockEyes + [(10, 7, "k"), (10, 8, "k"), (11, 7, "k"), (11, 8, "k"),
                                (5, 13, "w")]
        case .struggling:  // >< 눈 + 일자 입 + 땀 두 방울
            return [(6, 4, "k"), (7, 5, "k"), (8, 4, "k"),
                    (6, 11, "k"), (7, 10, "k"), (8, 11, "k"),
                    (10, 6, "k"), (10, 7, "k"), (10, 8, "k"), (10, 9, "k"),
                    (3, 14, "w"), (5, 13, "w")]
        case .knockedOut:  // X X 눈 + 크게 벌린 입
            return [(6, 3, "k"), (7, 4, "k"), (8, 5, "k"), (6, 5, "k"), (8, 3, "k"),
                    (6, 10, "k"), (7, 11, "k"), (8, 12, "k"), (6, 12, "k"), (8, 10, "k"),
                    (10, 7, "k"), (10, 8, "k"), (11, 7, "k"), (11, 8, "k")]
        case .unknown:  // 흰 네모 눈 (데이터 없음)
            return [(7, 4, "w"), (7, 5, "w"), (8, 4, "w"), (8, 5, "w"),
                    (7, 10, "w"), (7, 11, "w"), (8, 10, "w"), (8, 11, "w"),
                    (10, 6, "k"), (10, 7, "k"), (10, 8, "k"), (10, 9, "k")]
        }
    }

    public static func grid(for stage: FaceStage, frame: Int) -> [String] {
        var rows = body.map { Array($0) }
        for (row, col, ch) in facePatches(for: stage) {
            rows[row][col] = ch
        }
        var grid = rows.map { String($0) }
        if frame % 2 == 1 {
            grid.removeLast()
            grid.insert(String(repeating: ".", count: 16), at: 0)
        }
        return grid
    }
}
