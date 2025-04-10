shader_type spatial;

vec2 random(vec2 uv) {
	return vec2(fract(cos(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123));
}

float worley(vec2 uv, float columns, float rows) {
	float minimunDist = 1.0;
	
	vec2 indexUV = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fractUV = fract(vec2(uv.x * columns, uv.y * rows));
	
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = random(indexUV + neighbor);
			
			vec2 difference = neighbor + point - fractUV;
			float dist = length(difference);
			minimunDist = min(minimunDist, dist);
		}
	}
	
	return minimunDist;
}

void fragment() {
	//float worley = worley(UV, 15.0, 15.0);
	//COLOR = vec4( vec3( worley ), 1.0 );
}
