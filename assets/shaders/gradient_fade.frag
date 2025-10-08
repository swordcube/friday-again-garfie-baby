#pragma header

uniform vec4 quad; // position and size of a frame within a texture (love.Quad)

uniform bool horizontal;
uniform bool flip;

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec4 pixel = Texel(texture, textureCoords);
    vec2 fullCoord = textureCoords * vec2(textureSize(texture, 0));

    float texY = horizontal ? fullCoord.x : fullCoord.y;
    float localY = (texY - (horizontal ? quad.x : quad.y)) / (horizontal ? quad.z : quad.w);
    localY = clamp(localY, 0.0, 1.0);

    float fade = flip ? mix(1.0, 0.0, localY) : localY;
    pixel.a *= fade;
    return pixel * color;
}