#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uGridSpacing;
uniform float uLineWidth;
uniform vec4 uLineColor;
uniform float uIntersectionRadius;
uniform vec4 uIntersectionColor;

out vec4 fragColor;

// Line antialiasing function
vec2 getLineAlpha(vec2 dist, float lineWidth) {
    float halfWidth = lineWidth * 0.5;
    float pixelRange = 1.0; // Adjust this value to control antialiasing spread

    return vec2(1., 1.) - smoothstep(halfWidth - pixelRange, halfWidth + pixelRange, dist);
}

// Circle antialiasing function
float getCircleAlpha(float dist, float radius) {
    float pixelRange = 1.0; // Adjust this value to control antialiasing spread
    return 1.0 - smoothstep(radius - pixelRange, radius + pixelRange, dist);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    vec2 steps = round(fragCoord / uGridSpacing);

    vec2 lineCoords = steps * uGridSpacing;

    vec2 dxdy = abs(fragCoord - lineCoords);

    vec2 dirAlpha = getLineAlpha(dxdy, uLineWidth);

    float dist = distance(fragCoord, lineCoords);
    float intersectionAlpha = getCircleAlpha(dist, uIntersectionRadius);

    // Blend colors using the calculated alpha values
    vec4 lineColorWithAlpha = uLineColor * max(dirAlpha.x, dirAlpha.y);
    vec4 intersectionColorWithAlpha = uIntersectionColor * intersectionAlpha;

    // Blend between line and intersection colors
    fragColor = mix(lineColorWithAlpha, intersectionColorWithAlpha, intersectionAlpha);
}