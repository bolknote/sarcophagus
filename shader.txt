#define NUM_LIGHTS 100
struct Light {
vec2 position;
vec3 diffuse;
float power;
};

extern Light lights[NUM_LIGHTS];
extern int num_lights;
extern float t;
extern float f;
extern float am;
extern int dying;
extern int ci;


const float constant = 1.0;
const float quadratic = 0.5;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
vec4 pixel = Texel(image, uvs);
vec3 diffuse = vec3(am);
float attenuation;

if (dying==1)
{
	diffuse = vec3(0);
}

for (int i = 1; i < num_lights; i++)
{
	
	Light light = lights[i];

	float distance = length(light.position - screen_coords)+float(ci*20);

	float attenuation = float(1);



	if (distance < light.power + t*1.0) 
	{
		attenuation = 1.0;
	}
	else
	{
			if (distance < light.power * 1.25 - t*1.0) 
			{
				attenuation = 0.75;
			}
			else
			{

				if (distance < light.power * 1.7 + t*2.0) 
				{
					attenuation = 0.5;
				}
				else
				{
					if (distance < light.power * 2.25 + t*2.0) 
					{
						attenuation = (screen_coords.y/2.0 - floor (screen_coords.y / 2.0)) * 0.2;

					}
					else
					{
						attenuation = 0.0;
					}
				}

			}

	}


	float at = floor (screen_coords.y - floor ((screen_coords.y) / 3.0)*3.0);
	if (t==at) at = 0.5; else at = 1.0;


		
		diffuse += light.diffuse * attenuation;

		if (dying==1)
		{
			diffuse = diffuse * at;
		}



}




diffuse = clamp(diffuse, 0.0, 1.0);
diffuse = diffuse + 0.0;
diffuse = diffuse * f;

//|| (f<1 && t==1)

if (dying==1)
{

	number average = (pixel.r+pixel.b+pixel.g)/3.0;
	pixel.r = average;
	pixel.g = average;
	pixel.b = average;

}


return pixel * vec4(diffuse, 1.0) * color;
}