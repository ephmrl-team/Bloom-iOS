//
//  AccentGooey.metal
//  Bloom
//
//  A metaball bridge between two neighbouring accent swatches. The discs and the neck are one
//  smooth-union field, so the circles actually melt together. The silhouette keeps a crisp edge;
//  only the colour boundary is a soft gradient. The neck tapers into the target and fades out
//  while it thins, so no hairline is left behind.
//

#include <metal_stdlib>
using namespace metal;

// Polynomial smooth minimum: melts two distance fields into one liquid surface.
static float smoothMinimum(float a, float b, float k) {
    if (k <= 0.0001f) {
        return min(a, b);
    }
    float h = clamp(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
    return mix(b, a, h) - k * h * (1.0f - h);
}

[[ stitchable ]] half4 accentGooey(
    float2 position,
    half4 color,
    float2 from,
    float2 to,
    float progress,
    float neck,
    float radius,
    float selectedRadius,
    half4 fromColor,
    half4 toColor
) {
    float p = clamp(progress, 0.0f, 1.2f);
    float tension = clamp(neck, 0.0f, 1.0f);

    // The old swatch shrinks and the new one grows into each other.
    float fromRadius = mix(selectedRadius, radius, p);
    float toRadius = mix(radius, selectedRadius, p);

    float2 segment = to - from;
    float lengthSquared = max(dot(segment, segment), 0.0001f);
    float along = clamp(dot(position - from, segment) / lengthSquared, 0.0f, 1.0f);
    float2 closest = from + segment * along;

    float dFrom = length(position - from) - fromRadius;
    float dTo = length(position - to) - toRadius;

    // A clean, symmetric neck. It fades in and out as a whole, so no hairline or micro dot is
    // ever welded to the rim of either circle.
    float neckRadius = radius * 0.6f * tension;
    float neckPresence = smoothstep(0.0f, 6.0f, neckRadius);
    float dNeck = 1.0e6f;
    if (neckRadius > 0.01f) {
        dNeck = length(position - closest) - neckRadius + (1.0f - neckPresence) * 30.0f;
    }

    float k = 2.0f + 7.0f * tension;
    float distance = smoothMinimum(smoothMinimum(dFrom, dTo, k), dNeck, k);

    // Crisp silhouette: a one-point anti-aliased edge, never a blur.
    float alpha = 1.0f - smoothstep(-0.6f, 0.6f, distance);

    if (alpha <= 0.0f) {
        return half4(0.0h);
    }

    // Only the colour is blurred: a soft band around the middle of the bridge.
    float band = clamp(length(segment) / 220.0f, 0.16f, 0.5f);
    float blend = smoothstep(0.5f - band, 0.5f + band, along);
    half3 rgb = mix(fromColor.rgb, toColor.rgb, half(blend));
    half a = half(alpha);
    return half4(rgb * a, a);
}
