import Foundation

public enum ClaudeBarError: Error, LocalizedError {
    case keychainUnavailable(OSStatus)
    case credentialsMalformed
    case apiError(Int)

    public var errorDescription: String? {
        switch self {
        case .keychainUnavailable: return "키체인 접근이 거부되었어요"
        case .credentialsMalformed: return "로그인 정보를 해석하지 못했어요"
        case .apiError(let code): return "API 오류 (\(code))"
        }
    }
}

public struct UsageWindow: Equatable {
    public let percentUsed: Double
    public let resetsAt: Date?

    public var percentRemaining: Double { max(0, 100 - percentUsed) }

    public init(percentUsed: Double, resetsAt: Date?) {
        self.percentUsed = percentUsed
        self.resetsAt = resetsAt
    }
}

public struct UsageSnapshot: Equatable {
    public let session: UsageWindow
    public let weekly: UsageWindow

    public var displayRemaining: Double {
        min(session.percentRemaining, weekly.percentRemaining)
    }

    public init(session: UsageWindow, weekly: UsageWindow) {
        self.session = session
        self.weekly = weekly
    }
}

public enum FaceStage: Equatable {
    case calm, smile, worried, struggling, knockedOut, unknown

    public init(remaining: Double?) {
        guard let r = remaining else {
            self = .unknown
            return
        }
        switch r {
        case 60...: self = .calm
        case 40..<60: self = .smile
        case 20..<40: self = .worried
        case 5..<20: self = .struggling
        default: self = .knockedOut
        }
    }
}
