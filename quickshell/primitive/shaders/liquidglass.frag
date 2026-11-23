#version 440
// Liquid glass: the fragment shader of the liquid glass library (Dotfiles/liquidglass-main,
// src/shaders.ts, FS_GLASS), ported to a Qt Quick ShaderEffect (primitive/LiquidGlass.qml).
// The maths is the library's, line for line, with these changes for the shell:
//   - the shape is a disc or a band along a circle (the dials' shapes), not a rounded box
//   - what it sees is the wallpaper (primitive/Backdrop.qml), not the page behind it
//   - the rim's glow band is never wider than 1.5× the bevel (the library sizes it by
//     the shape, which on a big dial is a wide haze)
//   - two colours join in: `underColor` (what lies between the wallpaper and this glass,
//     e.g. the dial under a ring) and `tintColor` (the glass's own colour: it fills the
//     body and clears across the bevel, so the rim stays liquid on a solid dial)
// Every length is worked in device px, as the library does. After editing, run
// scripts/build-shaders.sh: Qt loads the compiled .qsb, not this file.

// px from the shape's centre (device px, y down), and where this pixel is on the window
// (0..1, y down)
layout(location = 0) in vec2 local;
layout(location = 1) in vec2 screenUV;
layout(location = 0) out vec4 fragColor;

// the same block as liquidglass.vert: each member is a property of LiquidGlass.qml
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // the item and the window, logical px
    vec2 itemSize;
    vec2 centre;
    float dpr;
    float ndcYUp;
    vec2 screenSize;

    // the shape: 0 disc, 1 band with round ends, 2 band with flat ends; its radius (a
    // band's middle line), a band's half width, the direction of its middle and (sin, cos)
    // of half its sweep
    float shapeKind;
    float shapeRadius;
    float shapeHalfWidth;
    vec2 arcMid;
    vec2 arcAperture;

    // screen UV → texture UV for each picture (xy scale, zw offset: it covers the screen)
    vec4 srcCover;
    vec4 blurCover;

    // the box the glass is clipped to (a dial clips to its own), item px: left, top, right,
    // bottom; right <= left for none
    vec4 clipBox;

    // straight (not premultiplied) colours; alpha is how much each covers
    vec4 underColor;
    vec4 tintColor;

    // the library's settings (GlassConfig), lengths in logical px
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

    // shape 3, a box: its half width and height (px); shapeRadius rounds its corners
    vec2 boxHalf;
};

// the wallpaper, and the same blurred (the Blur setting)
layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D srcBlur;

// Signed distance to the shape, device px (negative inside)
float sdShape(vec2 p) {
    float R = shapeRadius * dpr;
    if (shapeKind < 0.5)
        return length(p) - R;

    // a box with rounded corners (Inigo Quilez's sdRoundBox), for cards
    if (shapeKind > 2.5) {
        vec2 b = boxHalf * dpr;
        float r = min(R, min(b.x, b.y));
        vec2 q = abs(p) - b + r;
        return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    }
    float hw = shapeHalfWidth * dpr;

    // turned so the band's middle points down the y axis, then folded: it's symmetric
    vec2 q = vec2(p.x * arcMid.y - p.y * arcMid.x, p.x * arcMid.x + p.y * arcMid.y);
    q.x = abs(q.x);
    vec2 sc = arcAperture;

    // round ends (Inigo Quilez's sdArc): past the end, the distance to the end's centre
    if (shapeKind < 1.5) {
        float d = (sc.y * q.x > sc.x * q.y) ? length(q - sc * R) : abs(length(q) - R);
        return d - hw;
    }

    // flat ends, cut along the radius (Inigo Quilez's sdRing): turned once more so the
    // cut lies on the y axis
    vec2 r = vec2(q.x * sc.y - q.y * sc.x, q.x * sc.x + q.y * sc.y);
    return max(abs(length(q) - R) - hw,
               length(vec2(r.x, max(0.0, abs(r.y - R) - hw))) * sign(r.x));
}

// From the middle of the glass's body to p: a disc's middle is its centre, a band's is the
// circle it follows (the library's v_localPx, from the panel's centre)
vec2 bodyOffset(vec2 p) {
    if (shapeKind < 0.5 || shapeKind > 2.5) return p;
    float l = max(length(p), 1e-4);
    return p / l * (l - shapeRadius * dpr);
}

// Bevel height field: a half-circle profile, smooth at the peak, steep at the rim.
// d = distance inside from the edge, zR = the bevel's depth
float bevelHeight(float d, float zR) {
    if (d <= 0.0) return 0.0;
    if (d >= zR) return zR;
    return sqrt(d * (2.0 * zR - d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// a picture's UV for a point on the screen
vec2 cover(vec2 uv, vec4 c) {
    return uv * c.xy + c.zw;
}

void main() {
    vec2 p = local;
    float sdf = sdShape(p);
    float zR = max(zRadius * dpr, 1.0);

    // device px → screen UV (both y down, so no flip as in the library)
    vec2 pxToUV = 1.0 / max(screenSize * dpr, vec2(1.0));

    // ── shadow (outside the glass, dropped by shadowOffsetY) ──
    if (sdf > 0.0) {
        float sdfShadow = sdShape(p - vec2(0.0, shadowOffsetY * dpr));
        float d = max(sdfShadow - 1.0, 0.0);
        float spread = max(shadowSpread * dpr, 1.0);
        float falloff = 1.0 / (spread * spread);
        float outerShadow = exp(-d * d * falloff) * 0.65;
        float contactShadow = exp(-d * 0.08 / max(spread * 0.04, 0.01)) * 0.35;
        float shadow = (outerShadow + contactShadow) * shadowOpacity;

        // a clipped glass's shadow fades out before the clip, so where the dial meets the
        // screen's edge it tapers away instead of stopping on a straight line
        if (clipBox.z > clipBox.x) {
            vec2 q = p / dpr + centre;
            float dEdge = min(min(q.x - clipBox.x, clipBox.z - q.x), min(q.y - clipBox.y, clipBox.w - q.y));
            shadow *= smoothstep(0.0, max(shadowSpread * 2.0, 1.0), dEdge);
        }
        fragColor = vec4(0.0, 0.0, 0.0, shadow) * qt_Opacity;
        return;
    }

    // ── anti-aliased mask ──
    float mask = 1.0 - smoothstep(-1.5, 0.5, sdf);

    float maxD = (shapeKind < 0.5 ? shapeRadius : shapeKind > 2.5 ? min(boxHalf.x, boxHalf.y) : shapeHalfWidth) * dpr;
    float inside = -sdf;
    // the rim band: the library's 35% of the shape, but never wider than the bevel (×1.5),
    // so a big dial's rim stays a thin line of light instead of a wide haze
    float edge = smoothstep(min(maxD * 0.35, zR * 1.5), 0.0, inside);

    // ── surface normal (top surface) via the bevel height field ──
    float e = 2.0;
    float dR = -sdShape(p + vec2(e, 0.0));
    float dL = -sdShape(p - vec2(e, 0.0));
    float dU = -sdShape(p + vec2(0.0, e));
    float dD = -sdShape(p - vec2(0.0, e));
    float hC = bevelHeight(inside, zR);
    float hR = bevelHeight(dR, zR);
    float hL = bevelHeight(dL, zR);
    float hU = bevelHeight(dU, zR);
    float hD = bevelHeight(dD, zR);
    vec2 hGrad = vec2(hR - hL, hU - hD) / (2.0 * e);
    vec3 N = normalize(vec3(-hGrad, 1.0));

    float depth = smoothstep(0.0, zR, inside);

    // ── refraction ──
    vec2 v = bodyOffset(p);
    float ior = 1.5;
    float refrPow = 1.0 - 1.0 / ior;
    float thickness = hC * 2.0;
    float thickNorm = thickness / max(zR * 2.0, 1.0);
    vec2 refrPx;
    if (bevelMode < 0.5) {
        // biconvex: physically-based dual-surface refraction
        vec2 exitRefr = hGrad * refrPow;
        vec2 entryRefr = hGrad * refrPow;
        vec2 throughRefr = entryRefr * thickNorm * 0.5;
        refrPx = (exitRefr + entryRefr + throughRefr) * refraction * 30.0;
        vec2 centerDir = -v / max(maxD, 1.0);
        refrPx += centerDir * refraction * 4.0 * depth;
    } else {
        // dome (plano-convex): uniform magnification, drawn in towards the middle
        refrPx = -v * refraction * depth * 0.35;
    }
    vec2 refr = refrPx * pxToUV;

    // ── micro-distortion noise ──
    vec2 ns = p * 0.08;
    vec2 micro = (vec2(hash(ns), hash(ns + vec2(37.0))) - 0.5) * distortion * 4.0 * pxToUV;

    // ── chromatic aberration ──
    float caS = chroma * 18.0 * (edge * 0.7 + 0.3) * 2.0;
    vec2 caD = N.xy * caS * pxToUV;
    vec2 base = screenUV + refr + micro;

    vec3 sharp = vec3(
        texture(src, cover(base + caD, srcCover)).r,
        texture(src, cover(base, srcCover)).g,
        texture(src, cover(base - caD, srcCover)).b
    );
    vec3 blur = vec3(
        texture(srcBlur, cover(base + caD, blurCover)).r,
        texture(srcBlur, cover(base, blurCover)).g,
        texture(srcBlur, cover(base - caD, blurCover)).b
    );

    // ── edge-weighted blur mix ── the body sees the blurred picture, the rim leans
    // towards the sharp one so the refraction's edges stay crisp
    float edgeMix = 1.0 - edge * 0.15;
    vec3 col = mix(sharp, blur, edgeMix);

    // what lies between the wallpaper and this glass, over what it sees
    col = mix(col, underColor.rgb, underColor.a);

    // ── brightness ──
    col *= 1.0 + brightness;

    // ── saturation ──
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, 1.0 + saturation);

    // ── cool glass tint ──
    col = mix(col, col * vec3(0.92, 0.95, 1.05), coolTint);
    col *= 1.0 + 0.06 * depth;

    // the glass's own colour: solid through the body, clearing across the bevel to the rim
    col = mix(col, tintColor.rgb, tintColor.a * depth);

    // ── Fresnel ──
    float fres = pow(1.0 - abs(N.z), 4.0) * fresnel;

    // ── specular highlights (multi-light Blinn-Phong) ──
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 L1 = normalize(vec3(0.4, 0.7, 1.0));
    vec3 H1 = normalize(L1 + V);
    float sp1 = pow(max(dot(N, H1), 0.0), 90.0);
    vec3 L2 = normalize(vec3(-0.3, -0.5, 1.0));
    vec3 H2 = normalize(L2 + V);
    float sp2 = pow(max(dot(N, H2), 0.0), 50.0) * 0.3;
    vec3 L3 = normalize(vec3(0.1, 0.3, 1.0));
    float spB = pow(max(dot(N, L3), 0.0), 6.0) * 0.1;
    vec3 L4 = normalize(vec3(0.0, 0.9, 0.4));
    vec3 H4 = normalize(L4 + V);
    float sp4 = pow(max(dot(N, H4), 0.0), 120.0) * 0.6;
    float totalSpec = (sp1 + sp2 + spB + sp4) * specular;

    // ── inner border / stroke highlight ── brighter where the rim faces up (the
    // library's "top bias", from the rim's direction so it works on any shape)
    float borderWidth = 1.5;
    float innerStroke = smoothstep(-borderWidth - 1.0, -borderWidth, sdf)
                      * (1.0 - smoothstep(-1.0, 0.0, sdf));
    vec2 outward = normalize(vec2(dL - dR, dD - dU) + vec2(1e-6));
    float topBias = 0.5 + 0.5 * (-outward.y);
    innerStroke *= (0.4 + 0.6 * topBias);

    // ── edge highlight & inner glow ──
    float rim = edge * edgeHighlight * 0.22;
    float innerGlow = smoothstep(5.0, 0.0, -sdf) * edgeHighlight * 0.15;

    // ── environment-like reflection (fake) ──
    float envRefl = (N.y * 0.5 + 0.5) * fres * 0.08;

    // ── composite ──
    vec3 fin = col;
    fin += vec3(totalSpec);
    fin += vec3(rim + innerGlow);
    fin += vec3(innerStroke * edgeHighlight * 0.55);
    fin += vec3(envRefl);
    fin = mix(fin, vec3(1.0), fres * 0.2);
    fin = clamp(fin, 0.0, 1.0);

    // premultiplied, as Qt Quick blends
    float a = mask * glassOpacity;
    fragColor = vec4(fin * a, a) * qt_Opacity;
}
