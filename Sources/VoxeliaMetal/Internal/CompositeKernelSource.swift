// SPDX-License-Identifier: MIT

/// The embedded `MSL` source of the layer compositing compute kernel.
///
/// The source is the authoritative GPU model per `ADR-0096`: it
/// mirrors the `VOXELIA-ALG-0009` uniform composite-over structure in
/// `float32` because `MSL` has no 64-bit floating type, and it is
/// therefore claimed as an approximation of the registered binary64
/// model, never as that model. The shader manifest pins this exact
/// text by digest, and the suite verifies the pin.
enum CompositeKernelSource {
    static let metalSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VoxeliaCompositeParameters {
            uint elementCount;
            uint layerCount;
        };

        kernel void voxelia_composite_layers(
            device const uchar *layerSamples [[buffer(0)]],
            device const float *opacities [[buffer(1)]],
            device uchar *displaySamples [[buffer(2)]],
            constant VoxeliaCompositeParameters &parameters [[buffer(3)]],
            uint index [[thread_position_in_grid]]
        ) {
            if (index >= parameters.elementCount) {
                return;
            }
            float accumulator = 0.0f;
            for (uint layer = 0; layer < parameters.layerCount; layer++) {
                float opacity = opacities[layer];
                float sample = float(
                    layerSamples[layer * parameters.elementCount + index]);
                accumulator = accumulator * (1.0f - opacity) + sample * opacity;
            }
            float rounded = rint(accumulator);
            displaySamples[index] = uchar(clamp(rounded, 0.0f, 255.0f));
        }
        """
}
