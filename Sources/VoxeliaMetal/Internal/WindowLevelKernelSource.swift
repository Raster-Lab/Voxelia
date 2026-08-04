// SPDX-License-Identifier: MIT

/// The embedded `MSL` source of the window-level compute kernel.
///
/// The source is the authoritative GPU model per `ADR-0080`: it mirrors
/// the `VOXELIA-ALG-0002` branch structure in `float32` because `MSL`
/// has no 64-bit floating type, and it is therefore claimed as an
/// approximation of the registered binary64 model, never as that model.
/// The shader manifest pins this exact text by digest, and the suite
/// verifies the pin.
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

        kernel void voxelia_window_level_u8(
            device const uchar *storedSamples [[buffer(0)]],
            device uchar *displaySamples [[buffer(1)]],
            constant VoxeliaWindowLevelParameters &parameters [[buffer(2)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.sampleCount) {
                return;
            }
            float sample = float(storedSamples[index]);
            uchar result;
            if (sample <= parameters.lowerEdge) {
                result = 0;
            } else if (sample > parameters.upperEdge) {
                result = 255;
            } else {
                float mapped = ((sample - parameters.threshold)
                                / parameters.widthMinusOne + 0.5f) * 255.0f;
                float rounded = rint(mapped);
                result = uchar(clamp(rounded, 0.0f, 255.0f));
            }
            displaySamples[index] = result;
        }
        """
}
