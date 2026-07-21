import Foundation

public enum CharacterSprites {
    /// Clawd(Claude Code 마스코트) 몸통 베이스 (16×16).
    /// 실제 스프라이트 재현: 납작한 직사각 몸통(외곽선 없는 단색), 오른쪽 위 돌기,
    /// 양옆으로 뻗은 팔, 아래 다리 4개. 눈은 표정 패치로 그린다.
    /// '.'투명 'o'주황
    static let body: [String] = [
        "................",  // 0
        "............oo..",  // 1  오른쪽 위 돌기
        "...ooooooooooo..",  // 2  머리/몸통
        "...ooooooooooo..",  // 3
        "...ooooooooooo..",  // 4  (눈 위치)
        "...ooooooooooo..",  // 5
        "...ooooooooooo..",  // 6
        "oooooooooooooooo",  // 7  팔 (양옆으로 뻗음)
        "oooooooooooooooo",  // 8
        "oooooooooooooooo",  // 9
        "...ooooooooooo..",  // 10
        "...ooooooooooo..",  // 11
        "....o.o..o.o....",  // 12 다리 4개
        "....o.o..o.o....",  // 13
        "................",  // 14
        "................",  // 15
    ]

    /// 표정 패치: (row, col, char). Clawd 기본 눈 = 세로 슬릿(1×2) 두 개, 입 없음.
    static func facePatches(for stage: FaceStage) -> [(Int, Int, Character)] {
        // 세로 슬릿 눈 (원본 Clawd 눈)
        let slitEyes: [(Int, Int, Character)] = [
            (4, 5, "k"), (5, 5, "k"),
            (4, 10, "k"), (5, 10, "k"),
        ]
        switch stage {
        case .calm:  // 원본 그대로: 눈만, 입 없음
            return slitEyes
        case .smile:  // 슬릿 눈 + 웃는 입
            return slitEyes + [(8, 6, "k"), (9, 7, "k"), (9, 8, "k"), (8, 9, "k")]
        case .worried:  // 슬릿 눈 + 벌린 입 + 땀
            return slitEyes + [(8, 7, "k"), (8, 8, "k"), (9, 7, "k"), (9, 8, "k"),
                               (2, 14, "w")]
        case .struggling:  // >< 눈 + 일자 입 + 땀 두 방울
            return [(3, 4, "k"), (4, 5, "k"), (5, 4, "k"),
                    (3, 11, "k"), (4, 10, "k"), (5, 11, "k"),
                    (8, 6, "k"), (8, 7, "k"), (8, 8, "k"), (8, 9, "k"),
                    (1, 14, "w"), (3, 14, "w")]
        case .knockedOut:  // X X 눈 + 크게 벌린 입
            return [(3, 4, "k"), (4, 5, "k"), (5, 6, "k"), (3, 6, "k"), (5, 4, "k"),
                    (3, 9, "k"), (4, 10, "k"), (5, 11, "k"), (3, 11, "k"), (5, 9, "k"),
                    (8, 7, "k"), (8, 8, "k"), (9, 7, "k"), (9, 8, "k")]
        case .unknown:  // 흰 슬릿 눈 + 일자 입 (데이터 없음)
            return [(4, 5, "w"), (5, 5, "w"), (4, 10, "w"), (5, 10, "w"),
                    (8, 6, "k"), (8, 7, "k"), (8, 8, "k"), (8, 9, "k")]
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
