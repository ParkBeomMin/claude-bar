import Foundation

public enum CharacterSprites {
    /// 몸통 베이스 (16×16). '.'투명 'o'주황 'd'외곽선
    static let body: [String] = [
        "................",  // 0
        ".....dddddd.....",  // 1
        "...ddoooooodd...",  // 2
        "..dooooooooood..",  // 3
        ".dooooooooooood.",  // 4
        ".dooooooooooood.",  // 5
        ".dooooooooooood.",  // 6
        "ddoooooooooooodd",  // 7  ← 양옆 집게 팔
        "ddoooooooooooodd",  // 8
        ".dooooooooooood.",  // 9
        ".dooooooooooood.",  // 10
        "..dooooooooood..",  // 11
        "...ddoooooodd...",  // 12
        ".....dddddd.....",  // 13
        "....dd....dd....",  // 14 ← 발
        "................",  // 15
    ]

    /// 표정 패치: (row, col, char)
    static func facePatches(for stage: FaceStage) -> [(Int, Int, Character)] {
        switch stage {
        case .calm:  // 점 눈 + 작은 입
            return [(6, 5, "k"), (6, 10, "k"), (8, 7, "k"), (8, 8, "k")]
        case .smile:  // 점 눈 + 웃는 입
            return [(6, 5, "k"), (6, 10, "k"),
                    (8, 6, "k"), (9, 7, "k"), (9, 8, "k"), (8, 9, "k")]
        case .worried:  // 점 눈 + 벌린 입 + 땀 한 방울
            return [(6, 5, "k"), (6, 10, "k"),
                    (8, 7, "k"), (8, 8, "k"), (9, 7, "k"), (9, 8, "k"),
                    (3, 12, "w")]
        case .struggling:  // >< 눈 + 물결 입 + 땀 두 방울
            return [(5, 4, "k"), (6, 5, "k"), (7, 4, "k"),
                    (5, 11, "k"), (6, 10, "k"), (7, 11, "k"),
                    (9, 6, "k"), (9, 8, "k"),
                    (2, 12, "w"), (4, 13, "w")]
        case .knockedOut:  // X X 눈 + 벌린 입
            return [(5, 4, "k"), (6, 5, "k"), (7, 6, "k"), (5, 6, "k"), (7, 4, "k"),
                    (5, 9, "k"), (6, 10, "k"), (7, 11, "k"), (5, 11, "k"), (7, 9, "k"),
                    (9, 7, "k"), (9, 8, "k"), (10, 7, "k"), (10, 8, "k")]
        case .unknown:  // 소용돌이(흰) 눈 + 평평한 입
            return [(6, 5, "w"), (6, 10, "w"), (9, 7, "k"), (9, 8, "k")]
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
