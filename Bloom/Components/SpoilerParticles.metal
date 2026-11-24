//
//  SpoilerParticles.metal
//  Bloom
//
//  Procedural spoiler cloud: one dot per grid cell, so a pixel costs a constant
//  3x3 neighbourhood check instead of a loop over all dots.
//

#include <metal_stdlib>
using namespace metal;

/// Deterministic 2D hash in 0...1.
static float hash21(float2 p) {
    p = fract(p * float2(123.34f, 456.21f));
    p += dot(p, p + 45.32f);
    return fract(p.x * p.y);
}

/// Dots that drift, grow, shrink and change opacity. Hard edges: only the outermost
/// half pixel is antialiased, so the cloud reads as crisp dots, not a blur.
static float dots(float2 point, float2 size, float cellSize, float time) {
    float2 base = floor(point / cellSize);
    float total = 0.0f;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 id = base + float2(float(x), float(y));
            float r1 = hash21(id);
            float r2 = hash21(id + 31.7f);
            float r3 = hash21(id + 71.3f);
            float phase = r1 * 6.283f;

            float2 center = (id + 0.5f) * cellSize
                + float2(sin(time * 1.7f + phase), cos(time * 1.5f + phase + 2.1f)) * cellSize * 0.3f;
            float radius = mix(1.1f, 2.9f, r2) * (0.75f + 0.25f * sin(time * 2.2f + phase * 1.7f));
            float alpha = mix(0.6f, 1.0f, r3) * (0.8f + 0.2f * sin(time * 2.6f + phase));

            // A dot that nears the canvas edge just shrinks until it fits. Nothing is clipped and
            // no dot ever pops in or out: every value here changes continuously with time.
            float2 room = min(center, size - center);
            radius = min(radius, min(room.x, room.y));

            float d = length(point - center);
            float dot = (1.0f - smoothstep(radius - 0.15f, radius, d)) * alpha;
            // Overlaps keep the strongest dot instead of stacking into blobs.
            total = max(total, dot);
        }
    }
    return total;
}

/// `color` is the resolved fill of the view, so the cloud follows the light or dark theme.
/// One dot per 7 pt cell: the count follows the area instead of being fixed.
[[ stitchable ]] half4 spoilerParticles(float2 position, half4 color, float time, float2 size) {
    return half4(color.rgb, color.a * half(clamp(dots(position, size, 7.0f, time), 0.0f, 1.0f)));
}
