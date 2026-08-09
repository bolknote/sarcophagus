extern vec2 source_size;
extern float sharpness;

vec4 source_pixel(Image image, vec2 pixel_position)
{
	return Texel(image, (pixel_position + vec2(0.5)) / source_size);
}

vec4 smooth_pixel(Image image, vec2 pixel_position)
{
	vec2 base = floor(pixel_position);
	vec2 blend = fract(pixel_position);

	// This stable 2x interpolation changes only near texel boundaries, while
	// the centre of every texel stays crisp.
	blend = blend * blend * (vec2(3.0) - vec2(2.0) * blend);
	blend = clamp((blend - vec2(0.5)) * 1.25 + vec2(0.5), 0.0, 1.0);

	vec4 top = mix(
		source_pixel(image, base),
		source_pixel(image, base + vec2(1.0, 0.0)),
		blend.x
	);
	vec4 bottom = mix(
		source_pixel(image, base + vec2(0.0, 1.0)),
		source_pixel(image, base + vec2(1.0, 1.0)),
		blend.x
	);
	return mix(top, bottom, blend.y);
}

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords)
{
	vec2 pixel_position = uvs * source_size - vec2(0.5);
	vec4 pixel = smooth_pixel(image, pixel_position);

	// The first version brightened neighbouring pixels (a soft halo). Replace
	// that with a small, symmetric unsharp mask. The kernel does not classify
	// edges or change between frames, so movement remains stable.
	vec4 neighbours = (
		smooth_pixel(image, pixel_position + vec2(-1.0, 0.0))
		+ smooth_pixel(image, pixel_position + vec2(1.0, 0.0))
		+ smooth_pixel(image, pixel_position + vec2(0.0, -1.0))
		+ smooth_pixel(image, pixel_position + vec2(0.0, 1.0))
	) * 0.25;
	pixel.rgb += (pixel.rgb - neighbours.rgb) * sharpness;
	pixel.rgb = clamp(pixel.rgb, vec3(0.0), vec3(max(pixel.a, 0.0001)));

	return pixel * color;
}
