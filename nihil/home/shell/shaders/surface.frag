#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 1) in vec2 screenUv;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float ySign;
    float radius;
    float transmission;
    float refraction;
    float bevel;
    float rim;
    float outline;
    float dim;
    float frost;
    float scatter;
    float halo;
    float wobble;
    vec2 box;
    vec2 win;
    vec2 org;
    vec2 scr;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D backdrop;

float roundBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// From here to glass(), the same in frame.frag.
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 blurred(vec2 uv, float r, float turn, float px) {
    float lod = log2(max(r * px * 0.5, 1.0));
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float a = float(i) * 2.3999632 + turn;
        float s = r * sqrt((float(i) + 0.5) / 8.0);
        sum += textureLod(backdrop, uv + vec2(cos(a), sin(a)) * s / scr, lod).rgb;
    }
    return sum * 0.125;
}

vec3 glass(vec2 p, vec2 uv, vec2 n, float depth, vec3 smoke, float through) {
    float px = float(textureSize(backdrop, 0).x) / max(scr.x, 1.0);

    float k = clamp(1.0 - depth / max(bevel, 1.0), 0.0, 1.0);
    k *= k;
    vec2 bend = n * (refraction * k);

    vec2 q = p / 34.0;
    vec2 w = vec2(noise(q), noise(q + vec2(19.7, 7.3)))
        + 0.5 * vec2(noise(q * 2.7 + vec2(5.1, 13.9)), noise(q * 2.7 + vec2(23.4, 2.2)));
    w = w / 1.5 * 2.0 - 1.0;
    vec2 at = uv + (bend + w * wobble * (1.0 - k)) / scr;

    float soft = log2(max(1.25 * px, 1.0));
    vec3 clear;
    if (k > 0.01) {
        vec2 apart = bend * 0.14 / scr;
        clear = vec3(textureLod(backdrop, at - apart, soft).r,
                     textureLod(backdrop, at, soft).g,
                     textureLod(backdrop, at + apart, soft).b);
    } else {
        clear = textureLod(backdrop, at, soft).rgb;
    }
    float grain = hash(floor(p * px)) * 6.2831853;
    float uneven = 0.75 + 0.5 * noise(q * 1.7 + vec2(41.0, 3.0));
    vec3 frosted = blurred(at, frost * uneven, grain, px);
    float clarity = smoothstep(10.0, 24.0, bevel);
    vec3 behind = mix(frosted, clear, smoothstep(0.08, 0.7, k) * clarity) * dim;

    vec3 wide = vec3(0.0);
    float lw = log2(max(frost * 2.2 * px, 1.0));
    for (int i = 0; i < 4; i++) {
        float a = float(i) * 1.5707963 + 0.7853982 + grain * 0.15;
        wide += textureLod(backdrop, at + vec2(cos(a), sin(a)) * (frost * 1.6) / scr, lw).rgb;
    }
    wide *= 0.25 * dim;

    vec3 col = mix(smoke, behind, through);
    col += wide * scatter * (0.35 + through);

    float edge = exp(-depth / 2.5);
    vec2 past = uv + n * (3.0 + depth) / scr;
    vec3 near = textureLod(backdrop, past, log2(max(10.0 * px, 1.0))).rgb;
    vec3 around = textureLod(backdrop, past, log2(max(28.0 * px, 1.0))).rgb;
    col += max(near - around, 0.0) * (dim * halo * edge);

    float band = clamp(1.0 - depth / 2.5, 0.0, 1.0);
    float lit = pow(max(dot(n, vec2(-0.7071, -0.7071)), 0.0), 4.0);
    float away = pow(max(dot(n, vec2(0.7071, 0.7071)), 0.0), 2.0);
    col += vec3(rim * lit * band);
    col *= 1.0 - 0.3 * away * band;
    col += vec3(0.03 * k);

    col += (hash(gl_FragCoord.xy) - 0.5) / 255.0;
    return max(col, vec3(0.0));
}

void main() {
    vec2 halfSize = box * 0.5;
    vec2 p = qt_TexCoord0 * box - halfSize;
    float r = min(radius, min(halfSize.x, halfSize.y));
    float d = roundBox(p, halfSize, r);
    float cover = clamp(0.5 - d, 0.0, 1.0);
    if (cover <= 0.0 || tint.a + outline <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 e = vec2(0.5, 0.0);
    vec2 n = vec2(roundBox(p + e.xy, halfSize, r) - roundBox(p - e.xy, halfSize, r),
                  roundBox(p + e.yx, halfSize, r) - roundBox(p - e.yx, halfSize, r));
    n /= max(length(n), 1e-4);
    float depth = max(-d, 0.0);

    if (outline > 0.5 && tint.a <= 0.01) {
        float ring = clamp(1.0 - depth / 1.5, 0.0, 1.0);
        float lit = pow(max(dot(n, vec2(-0.7071, -0.7071)), 0.0), 4.0);
        vec3 behind = textureLod(backdrop, screenUv, 0.0).rgb * dim;
        vec3 col = behind * 0.5 + vec3(0.18 + rim * lit);
        float a = cover * ring;
        fragColor = vec4(col * a, a) * qt_Opacity;
        return;
    }

    float luma = dot(tint.rgb, vec3(0.2126, 0.7152, 0.0722));
    float through = mix(transmission, 0.1, smoothstep(0.15, 0.6, luma));
    vec3 col = glass(p + halfSize, screenUv, n, depth, tint.rgb, through);
    float a = cover * tint.a;
    fragColor = vec4(col * a, a) * qt_Opacity;
}
