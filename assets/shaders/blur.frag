#pragma header

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec4 pixel = Texel(texture, textureCoords, 12.5);
    pixel.rgb = vec3(1.0);
    return pixel * color;
}