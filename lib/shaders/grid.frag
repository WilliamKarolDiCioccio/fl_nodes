#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform float uGridSpacingX;
uniform float uGridSpacingY;
uniform float uLineWidth;
uniform vec4 uLineColor;
uniform float uIntersectionRadius;
uniform vec4 uIntersectionColor;
uniform vec4 uViewport;

out vec4 fragColor;

// Antialiasing helper function
float smoothStep(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

// Line antialiasing function
float getLineAlpha(float dist, float lineWidth) {
    float halfWidth = lineWidth * 0.5;
    float pixelRange = 1.0; // Adjust this value to control antialiasing spread
    
    return 1.0 - smoothStep(halfWidth - pixelRange, halfWidth + pixelRange, dist);
}

// Circle antialiasing function
float getCircleAlpha(float dist, float radius) {
    float pixelRange = 1.0; // Adjust this value to control antialiasing spread
    return 1.0 - smoothStep(radius - pixelRange, radius + pixelRange, dist);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    float x = fragCoord.x;
    float y = fragCoord.y;

    float viewportLeft = uViewport.x;
    float viewportTop = uViewport.y;
    float viewportRight = uViewport.z;
    float viewportBottom = uViewport.w;

    // Discard fragments outside the viewport
    if (x < viewportLeft || x > viewportRight || y < viewportTop || y > viewportBottom) {
        fragColor = vec4(0.0);
        return;
    }

    // Calculate start positions within the shader
    float startX = floor(viewportLeft / uGridSpacingX) * uGridSpacingX;
    float startY = floor(viewportTop / uGridSpacingY) * uGridSpacingY;

    float verticalAlpha = 0.0;
    float horizontalAlpha = 0.0;
    float intersectionAlpha = 0.0;

    // Calculate vertical line alpha
    if (uGridSpacingX > 0.0) {
        float xSteps = round((x - startX) / uGridSpacingX);
        float lineX = startX + xSteps * uGridSpacingX;
        if (lineX >= viewportLeft && lineX <= viewportRight) {
            float dx = abs(x - lineX);
            verticalAlpha = getLineAlpha(dx, uLineWidth);
        }
    }

    // Calculate horizontal line alpha
    if (uGridSpacingY > 0.0) {
        float ySteps = round((y - startY) / uGridSpacingY);
        float lineY = startY + ySteps * uGridSpacingY;
        if (lineY >= viewportTop && lineY <= viewportBottom) {
            float dy = abs(y - lineY);
            horizontalAlpha = getLineAlpha(dy, uLineWidth);
        }
    }

    // Calculate intersection alpha
    if (uIntersectionRadius > 0.0 && uGridSpacingX > 0.0 && uGridSpacingY > 0.0) {
        float xSteps = round((x - startX) / uGridSpacingX);
        float ySteps = round((y - startY) / uGridSpacingY);
        vec2 intersection = vec2(
            startX + xSteps * uGridSpacingX,
            startY + ySteps * uGridSpacingY
        );
        
        if (intersection.x >= viewportLeft && intersection.x <= viewportRight &&
            intersection.y >= viewportTop && intersection.y <= viewportBottom) {
            float dist = distance(fragCoord, intersection);
            intersectionAlpha = getCircleAlpha(dist, uIntersectionRadius);
        }
    }

    // Blend colors using the calculated alpha values
    vec4 lineColorWithAlpha = uLineColor * max(verticalAlpha, horizontalAlpha);
    vec4 intersectionColorWithAlpha = uIntersectionColor * intersectionAlpha;
    
    // Blend between line and intersection colors
    fragColor = mix(lineColorWithAlpha, intersectionColorWithAlpha, intersectionAlpha);
}