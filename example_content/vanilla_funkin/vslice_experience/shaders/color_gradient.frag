#pragma header

uniform vec4 blackColor;
uniform vec4 whiteColor;

void main() {
    vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
    gl_FragColor = vec4(mix(blackColor.rgb, whiteColor.rgb, col.a > 0.0 ? col.r / col.a : 0.0) * col.a, col.a);
}