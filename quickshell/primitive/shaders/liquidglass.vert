#version 440
// Liquid glass, vertex side (see liquidglass.frag). Besides the usual position it works out
// where each corner of the item lands on the window, from qt_Matrix itself, so the glass
// always sees the part of the wallpaper behind it, wherever it is and however it moves.
// After editing, run scripts/build-shaders.sh.

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

// px from the shape's centre (device px, y down), and where this point is on the window
// (0..1, y down)
layout(location = 0) out vec2 local;
layout(location = 1) out vec2 screenUV;

// the same block as liquidglass.frag
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec2 centre;
    float dpr;
    float ndcYUp;
    vec2 screenSize;
    float shapeKind;
    float shapeRadius;
    float shapeHalfWidth;
    vec2 arcMid;
    vec2 arcAperture;
    vec4 srcCover;
    vec4 blurCover;
    vec4 clipBox;
    vec4 underColor;
    vec4 tintColor;
    float refraction;
    float chroma;
    float edgeHighlight;
    float specular;
    float fresnel;
    float distortion;
    float zRadius;
    float glassOpacity;
    float saturation;
    float coolTint;
    float brightness;
    float shadowOpacity;
    float shadowSpread;
    float shadowOffsetY;
    float bevelMode;
    vec2 boxHalf;
};

out gl_PerVertex { vec4 gl_Position; };

void main() {
    local = (qt_MultiTexCoord0 * itemSize - centre) * dpr;
    gl_Position = qt_Matrix * qt_Vertex;

    // the window's clip space: y points up on OpenGL (ndcYUp 1), down on Vulkan (-1)
    vec2 ndc = gl_Position.xy / gl_Position.w;
    screenUV = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5 * ndcYUp);
}
