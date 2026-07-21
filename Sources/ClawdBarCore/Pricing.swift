import Foundation

public struct ModelPricing: Equatable {
    public let input: Double
    public let output: Double
    public let cacheWrite: Double
    public let cacheRead: Double
}

public enum Pricing {
    /// USD per 1M tokens. 캐시 쓰기 5분 TTL(1.25×) 기준 근사.
    public static func pricing(forModel model: String) -> ModelPricing {
        if model.contains("fable") || model.contains("mythos") { return make(10, 50) }
        if model.contains("opus-4-1") || model.contains("opus-4-0") || model.contains("opus-4-2025") {
            return make(15, 75)
        }
        if model.contains("opus") { return make(5, 25) }
        if model.contains("haiku") { return make(1, 5) }
        return make(3, 15)  // sonnet 계열 + 미지의 모델
    }

    public static func cost(model: String, input: Int, output: Int, cacheWrite: Int, cacheRead: Int) -> Double {
        let p = pricing(forModel: model)
        return (Double(input) * p.input
              + Double(output) * p.output
              + Double(cacheWrite) * p.cacheWrite
              + Double(cacheRead) * p.cacheRead) / 1_000_000
    }

    private static func make(_ input: Double, _ output: Double) -> ModelPricing {
        ModelPricing(input: input, output: output, cacheWrite: input * 1.25, cacheRead: input * 0.1)
    }
}
