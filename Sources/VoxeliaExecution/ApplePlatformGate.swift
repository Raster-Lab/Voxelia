// SPDX-License-Identifier: MIT

#if !(os(macOS) || os(iOS) || os(tvOS) || os(visionOS))
    #error("Voxelia supports Apple operating systems only.")
#endif

#if !arch(arm64)
    #error("Voxelia requires Apple Silicon ARM64.")
#endif
