// SPDX-License-Identifier: MIT

import Foundation

@main
struct VoxeliaRepositoryCheck {
    static func main() throws {
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("--self-check") {
            print("{\"tool\":\"voxelia-repo-check\",\"status\":\"pass\"}")
            return
        }
        print("Voxelia repository tool scaffold")
        print("Use Tools/Scripts/validate-scaffold.sh for the complete M0 check.")
    }
}
