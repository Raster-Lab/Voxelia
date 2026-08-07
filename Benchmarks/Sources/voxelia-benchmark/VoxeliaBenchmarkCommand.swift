// SPDX-License-Identifier: MIT

import Foundation
import Voxelia

@main
struct VoxeliaBenchmarkCommand {
    static func main() async throws {
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("--frames") {
            try await FrameRateScenario.run()
            return
        }
        if arguments.contains("--self-check") {
            let start = ContinuousClock.now
            var accumulator = 0
            for value in 0..<10_000 {
                accumulator &+= value
            }
            let duration = start.duration(to: .now)
            let result: [String: Any] = [
                "benchmark": "voxelia.scaffold.noop",
                "status": accumulator > 0 ? "pass" : "fail",
                "elapsed": String(describing: duration),
            ]
            let data = try JSONSerialization.data(
                withJSONObject: result,
                options: [.prettyPrinted, .sortedKeys]
            )
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }

        print("Voxelia benchmark scaffold")
        print("Usage: voxelia-benchmark --self-check | --frames")
    }
}
