// SPDX-License-Identifier: MIT

/// The embedded `MSL` source of the window-level compute kernels.
///
/// The source is the authoritative GPU model per `ADR-0080`, extended
/// by `ADR-0093` with the 16-bit entry points: every entry point calls
/// the one shared mapping helper mirroring the `VOXELIA-ALG-0002`
/// branch structure in `float32`, because `MSL` has no 64-bit floating
/// type, and is therefore claimed as an approximation of the
/// registered binary64 model, never as that model. The shader manifest
/// pins this exact text by digest, and the suite verifies the pin.
enum WindowLevelKernelSource {
    static let metalSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VoxeliaWindowLevelParameters {
            float threshold;
            float lowerEdge;
            float upperEdge;
            float widthMinusOne;
            uint sampleCount;
        };

        static inline uchar voxelia_window_map(
            float sample,
            constant VoxeliaWindowLevelParameters &parameters
        ) {
            if (sample <= parameters.lowerEdge) {
                return 0;
            }
            if (sample > parameters.upperEdge) {
                return 255;
            }
            float mapped = ((sample - parameters.threshold)
                            / parameters.widthMinusOne + 0.5f) * 255.0f;
            float rounded = rint(mapped);
            return uchar(clamp(rounded, 0.0f, 255.0f));
        }

        kernel void voxelia_window_level_u8(
            device const uchar *storedSamples [[buffer(0)]],
            device uchar *displaySamples [[buffer(1)]],
            constant VoxeliaWindowLevelParameters &parameters [[buffer(2)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.sampleCount) {
                return;
            }
            displaySamples[index] =
                voxelia_window_map(float(storedSamples[index]), parameters);
        }

        kernel void voxelia_window_level_i16(
            device const short *storedSamples [[buffer(0)]],
            device uchar *displaySamples [[buffer(1)]],
            constant VoxeliaWindowLevelParameters &parameters [[buffer(2)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.sampleCount) {
                return;
            }
            displaySamples[index] =
                voxelia_window_map(float(storedSamples[index]), parameters);
        }

        kernel void voxelia_window_level_u16(
            device const ushort *storedSamples [[buffer(0)]],
            device uchar *displaySamples [[buffer(1)]],
            constant VoxeliaWindowLevelParameters &parameters [[buffer(2)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.sampleCount) {
                return;
            }
            displaySamples[index] =
                voxelia_window_map(float(storedSamples[index]), parameters);
        }
        """
}
