import XCTest
@testable import ClaudeBarCore

final class CharacterSpritesTests: XCTestCase {
    let allStages: [FaceStage] = [.calm, .smile, .worried, .struggling, .knockedOut, .unknown]

    func testAllGridsAre16x16WithValidChars() {
        let valid = Set(".odkw")
        for stage in allStages {
            for frame in [0, 1] {
                let grid = CharacterSprites.grid(for: stage, frame: frame)
                XCTAssertEqual(grid.count, 16, "\(stage) frame\(frame) row count")
                for row in grid {
                    XCTAssertEqual(row.count, 16, "\(stage) frame\(frame) row width: \(row)")
                    XCTAssertTrue(row.allSatisfy { valid.contains($0) }, "invalid char in \(row)")
                }
            }
        }
    }

    func testFrame1IsShiftedDownByOneRow() {
        let base = CharacterSprites.grid(for: .calm, frame: 0)
        let shifted = CharacterSprites.grid(for: .calm, frame: 1)
        XCTAssertEqual(shifted[0], String(repeating: ".", count: 16))
        XCTAssertEqual(Array(shifted[1...15]), Array(base[0...14]))
    }

    func testStagesHaveDistinctFaces() {
        let grids = allStages.map { CharacterSprites.grid(for: $0, frame: 0) }
        XCTAssertEqual(Set(grids.map { $0.joined() }).count, allStages.count)
    }
}
