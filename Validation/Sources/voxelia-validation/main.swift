// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaValidation

@main
struct VoxeliaValidationCommand {
    static func main() throws {
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("--self-check") {
            let result: [String: Any] = [
                "tool": "voxelia-validation",
                "schemaVersion": "0.1",
                "status": "pass",
            ]
            let data = try JSONSerialization.data(
                withJSONObject: result,
                options: [.prettyPrinted, .sortedKeys]
            )
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }

        print("Voxelia validation scaffold")
        print("Usage: voxelia-validation --self-check")
    }
}
