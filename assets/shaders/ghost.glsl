vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    float luminance = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    vec3 white_shading = mix(vec3(0.72), vec3(1.0), luminance);
    return vec4(white_shading, pixel.a) * color;
}
