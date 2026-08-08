extern float t;
const float constant = 1.0;
const float linear = 0.09;
const float quadratic = 0.5;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
vec4 pixel = Texel(image, uvs);
vec3 diffuse = vec3(0);

float attenuation;

attenuation = 1.0;

float at = floor (screen_coords.y - floor ((screen_coords.y) / 9.0)*9.0);
float at2 = floor (t/2.0+screen_coords.x - floor ((t/2.0+screen_coords.x) / 8.0)*8.0);
float at3;
float at4;

if (at2<4.0) {
at3 = floor (t-screen_coords.y+screen_coords.x - floor ((t-screen_coords.y+screen_coords.x) / 4.0)*4.0);
at4 = floor (screen_coords.y+screen_coords.x - floor ((screen_coords.y+screen_coords.x) / 5.0)*5.0);

}
else
{
at3 = floor (screen_coords.y-screen_coords.x - floor ((screen_coords.y-screen_coords.x) / 4.0)*4.0);
at4 = floor (t/3.0-screen_coords.y+screen_coords.x - floor ((t/3.0-screen_coords.y+screen_coords.x) / 3.0)*3.0);
}

if (at3 == 1.0)
{
	at3 = 0.6;
}
else
{
	at3 = 1.0;

	if (at4 == 1.0)
	{
		at3 = 1.4;
	}
}


diffuse += 1.0 * attenuation * at3;
diffuse = clamp(diffuse, 0.0, 2.0);
return pixel * vec4(diffuse, 1.0) * color;
}
