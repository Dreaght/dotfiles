#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float timePhase;
    float energy;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D spectrumSource;

vec3 palette(float t) {
    vec3 a = vec3(0.98, 0.54, 0.78);
    vec3 b = vec3(0.98, 0.76, 0.42);
    vec3 c = vec3(0.56, 0.92, 0.96);
    vec3 d = vec3(0.74, 0.64, 0.99);

    if (t < 0.33) return mix(a, b, t / 0.33);
    if (t < 0.66) return mix(b, c, (t - 0.33) / 0.33);
    return mix(c, d, (t - 0.66) / 0.34);
}

float sampleSpectrum(float x, float y) {
    return texture(spectrumSource, vec2(clamp(x, 0.0, 1.0), clamp(y, 0.0, 1.0))).r;
}

float smoothSpectrum(float x, float y) {
    float spread = 0.014 + energy * 0.050;
    float sum = 0.0;
    float weight = 0.0;

    for (int i = -6; i <= 6; ++i) {
        float fi = float(i);
        float w = exp(-abs(fi) * 0.42);
        sum += sampleSpectrum(x + fi * spread, y) * w;
        weight += w;
    }

    return sum / max(weight, 0.001);
}

float ridge(float y, float center, float thickness) {
    return smoothstep(thickness, 0.0, abs(y - center));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 centered = uv - vec2(0.5);
    float edgeFade = smoothstep(0.00, 0.18, uv.x) * (1.0 - smoothstep(0.82, 1.00, uv.x));

    float wave1 = sin(uv.x * 5.0 + timePhase * 6.28318) * (0.026 + energy * 0.030);
    float wave2 = sin(uv.x * 9.0 - timePhase * 3.71239 + uv.y * 2.2) * (0.018 + energy * 0.020);
    float wave3 = cos(uv.x * 4.2 + timePhase * 2.74159) * (0.021 + energy * 0.022);
    float flow = wave1 + wave2 + wave3;

    float upperA = smoothSpectrum(uv.x + flow * 0.45, 0.32);
    float upperB = smoothSpectrum(uv.x * 0.86 + 0.07 + flow * 0.24, 0.42);
    float lowerA = smoothSpectrum(uv.x * 1.08 - 0.03 - flow * 0.20, 0.68);
    float lowerB = smoothSpectrum(uv.x * 0.94 + 0.03 - flow * 0.28, 0.58);

    float upperField = mix(upperA, upperB, 0.46);
    float lowerField = mix(lowerA, lowerB, 0.46);
    float field = (upperField + lowerField) * 0.5;
    float lift = 0.08 + field * (0.42 + energy * 0.42);
    float bounce = (wave1 * 0.9 + wave2 * 0.75 + wave3 * 0.65);

    float baseCenter = 0.58;
    float bandA = ridge(uv.y, baseCenter - upperField * (0.14 + energy * 0.08) + bounce * 0.95, 0.18 + upperField * 0.16);
    float bandB = ridge(uv.y, baseCenter + lowerField * (0.12 + energy * 0.08) - bounce * 0.82, 0.20 + lowerField * 0.18);
    float bandC = ridge(uv.y, baseCenter - 0.02 + (upperField - lowerField) * 0.16 + bounce * 0.60, 0.24 + field * 0.14);

    float curtain = bandA * 0.44 + bandB * 0.40 + bandC * 0.28;
    curtain *= 0.24 + field * 1.10;

    float bloom = exp(-dot(centered * vec2(0.95, 1.5), centered * vec2(0.95, 1.5)) * 3.0) * (0.10 + energy * 0.22);
    float haze = smoothstep(1.0, 0.22, uv.y) * (0.03 + field * 0.06);

    float hueA = fract(0.08 + timePhase * 0.10 + upperField * 0.20 + centered.x * 0.16 + wave1 * 0.10);
    float hueB = fract(0.48 + timePhase * 0.08 + lowerField * 0.22 - centered.x * 0.12 + wave2 * 0.08);
    float hueC = fract(0.78 + timePhase * 0.06 + field * 0.18 + wave3 * 0.10);

    vec3 colorA = palette(hueA);
    vec3 colorB = palette(hueB + 0.18);
    vec3 colorC = palette(hueC);
    vec3 color = colorA * curtain + colorB * (bloom + haze) + colorC * (curtain * 0.18);

    color += vec3(0.02, 0.03, 0.05) * (0.24 + energy * 0.12);
    color = mix(color, color * 1.08, smoothstep(0.14, 0.78, field));
    color *= edgeFade;

    float alpha = clamp(curtain * 0.82 + bloom + haze, 0.0, 0.74) * edgeFade;
    fragColor = vec4(color, alpha) * qt_Opacity;
}
