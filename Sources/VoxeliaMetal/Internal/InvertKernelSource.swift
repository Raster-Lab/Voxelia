// SPDX-License-Identifier: MIT

/// The embedded `MSL` source of the display-inversion compute kernel.
///
/// The source is the authoritative GPU model per `ADR-0132`: the
/// registered `VOXELIA-ALG-0011` involution is pure unsigned
/// eight-bit integer arithmetic, so this kernel computes the
/// registered model exactly — no floating-point step exists and no
/// approximation claim is needed. The shader manifest pins this exact
/// text by digest, and the suite verifies the pin.
enum InvertKernelSource {
    static let metalSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VoxeliaInvertParameters {
            uint sampleCount;
        };

        kernel void voxelia_invert_display_u8(
            device const uchar *storedSamples [[buffer(0)]],
            device uchar *displaySamples [[buffer(1)]],
            constant VoxeliaInvertParameters &parameters [[buffer(2)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.sampleCount) {
                return;
            }
            displaySamples[index] = 255 - storedSamples[index];
        }
        """
}
