#pragma header
const int Samples = 32; //multiple of 2
uniform float Intensity = 0.6;
uniform vec2 Direction;
uniform float iTime;

const bool UseNoise = false;
const float NoiseScale = 1.;
const float NoiseStrength = 0.15;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 DirectionalBlur(in vec2 UV, in vec2 Direction, in float Intensity, in Image Texture)
{
    vec4 Color = vec4(0.0);  
    float Noise = (fract(sin(dot(vec2(iTime, iTime), vec2(12.9898,78.233)*2.0)) * 43758.5453));
    if (UseNoise==false)
    for (int i=1; i<=Samples/2; i++)
    {
        vec2 timethingy = vec2(iTime + float(i), iTime + float(i));
        float giveUsTheNumber = mix(rand(vec2(i, i) + iTime - mod(iTime, 1.0)), rand(vec2(i, i) + iTime-mod(iTime, 1.0)+1.0), mod(iTime, 1.0));
        float giveUsTheNumber2 = mix(rand(vec2(i, i) + iTime - mod(iTime, 1.0)), rand(vec2(i, i) + iTime-mod(iTime, 1.0)+1.0), mod(iTime, 1.0));
    vec2 NoiseThingy = vec2(giveUsTheNumber * Direction.x, giveUsTheNumber2 * Direction.y) * Intensity * 0.8;
    Color += Texel(Texture,NoiseThingy+UV+float(i)*Intensity/float(Samples/2)*Direction);
    Color += Texel(Texture,NoiseThingy+UV-float(i)*Intensity/float(Samples/2)*Direction);
    }
    else      
    for (int i=1; i<=Samples/2; i++)
    {
    Color += Texel(Texture,UV+float(i)*Intensity/float(Samples/2)*(Direction*(NoiseStrength*Noise)));
    Color += Texel(Texture,UV-float(i)*Intensity/float(Samples/2)*(Direction*(NoiseStrength*Noise)));  
    }    
    return Color/float(Samples);    
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 UV = textureCoords.xy;
    vec4 outputColor = DirectionalBlur(UV,normalize(Direction),Intensity, texture);
    //vec4 outputColor = Texel(texture, textureCoords);
    return outputColor * color;
}