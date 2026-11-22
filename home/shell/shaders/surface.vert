#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 qt_TexCoord0;
layout(location = 1) out vec2 screenUv;

// The same block as surface.frag's.
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

out gl_PerVertex { vec4 gl_Position; };

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
    vec2 ndc = gl_Position.xy / gl_Position.w;
    vec2 inWindow = vec2(ndc.x * 0.5 + 0.5, ndc.y * 0.5 * ySign + 0.5) * win;
    screenUv = (org + inWindow) / scr;
}
