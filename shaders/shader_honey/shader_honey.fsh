varying vec2 v_vTexcoord;

uniform float current_time;
uniform sampler2D noise_texture;

vec2 getUVOffset(vec2 baseUV, float t) {
	// Pirated from https://medium.com/@gordonnl/the-ocean-170fdfd659f1 -- ty MIT license <3
	vec2 uv = (baseUV * 10.0) + vec2(t * -0.05);
    uv.y += 0.01 * (sin(uv.x * 3.5 + t * 0.35) + sin(uv.x * 4.8 + t * 1.05) + sin(uv.x * 7.3 + t * 0.45)) / 3.0;
    uv.x += 0.12 * (sin(uv.y * 4.0 + t * 0.5) + sin(uv.y * 6.8 + t * 0.75) + sin(uv.y * 11.3 + t * 0.2)) / 3.0;
    uv.y += 0.12 * (sin(uv.x * 4.2 + t * 0.64) + sin(uv.x * 6.3 + t * 1.65) + sin(uv.x * 8.2 + t * 0.45)) / 3.0;
	return uv;
}

void main()
{
	vec2 noiseUV = getUVOffset(v_vTexcoord / 100.0, current_time / 10.0);
	float noise = texture2D(noise_texture, noiseUV).r;
	float alpha = texture2D(gm_BaseTexture, v_vTexcoord).a + (noise * 0.5);
	//alpha = 1.0 - pow(1.0 - alpha, 3.0);
	
	vec4 color = vec4(0.482, 0.259, 0.333, 1.0);
	if (alpha > 0.99) {
		color = vec4(0.902, 0.827, 0.725, 1.0);
	} else if (alpha > 0.7) {
		color = vec4(0.922, 0.741, 0.549, 1.0);
	} else if (alpha > 0.2) {
		color = vec4(0.839, 0.467, 0.51, 1.0);	
	}
	
    gl_FragColor = color;
}
