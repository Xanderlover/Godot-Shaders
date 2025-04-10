shader_type spatial;
render_mode blend_add, cull_disabled;

uniform vec3 color : source_color;
uniform vec3 colorIntersection : source_color = vec3(1.0,1.0,1.0);
uniform vec3 colorFresnel : source_color = vec3(1.0,1.0,1.0);
uniform float fill : hint_range(0.0, 0.25, 0.001) = 0.01;

//group_uniforms intersection;
uniform sampler2D depthTexture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float intersectionOffset : hint_range(0.0, 1.0, 0.001) = 0.15;

//group_uniforms fresnel;
uniform float fresnelPower : hint_range(0.0, 25.0, 0.001) = 5.0;

group_uniforms pattern;
uniform sampler2D scrollPattern;
uniform float scrollSpeed : hint_range(0.0, 0.5, 0.001) = 0.05;
uniform float patternTransparency : hint_range(0.0, 1.0, 0.001);
uniform vec2 tiling = vec2(4.0, 2.0);
uniform vec2 offset;
//uniform sampler2D distortion;
//uniform float distortionIntensity : hint_range(0.0, 1.0, 0.001) = 0.5;

group_uniforms erosion;
uniform float erosionThreshold : hint_range(0.0, 10.0, 0.001) = 0.0;
uniform sampler2D erosionNoise;

group_uniforms lighting;
#define USE_LIGHTING
varying vec3 wPos; // world position
varying vec3 V; // camera view
uniform float gloss : hint_range(0.0, 5.0, 0.001) = 1.0;

void vertex() {
	// tiling and scrolling pattern
	UV = UV * tiling + offset + TIME * scrollSpeed;

	//VERTEX.xyz += NORMAL * cos( -UV.y * TIME * 1.0 ) * 0.05; // pretty wobble effect
}

vec4 Multiply(vec4 base, vec4 blend){
	return base * blend;
}

void fragment() {

	// intersection (proximity/depth fade)
	float depth = texture(depthTexture, SCREEN_UV).r;
	vec4 depthWorldPos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	depthWorldPos.xyz /= depthWorldPos.w;
	float intersection = clamp(smoothstep(depthWorldPos.z + intersectionOffset, depthWorldPos.z, VERTEX.z), 0.0, 1.0);

	// fresnel
	vec3 N = normalize(NORMAL);
	V = VIEW;

	float fresnel = pow( 1.0-clamp(dot(N, V), 0.0, 1.0), fresnelPower );
	fresnel *= ( cos( TIME * 4.0 ) )*0.5+1.5; // flashy fresnel effect

	// pattern
	vec4 pattern = texture( scrollPattern, UV );

	// distortion
	//vec2 noise = UV * tiling + offset * TIME;
	//float noiseTexture = texture( distortion, UV ).r;
	//vec2 distortionUV = UV + noiseTexture * distortionIntensity;
	//vec4 distortionTexture = texture(scrollPattern, distortionUV);

	// erosion (dissolve)
	float erosionTexture = texture( erosionNoise, UV ).r;
	float erosionValue = clamp( smoothstep(0.0, erosionThreshold, erosionTexture), 0.0, 1.0 );
	float erosionHighlights = step( erosionTexture, erosionValue );

	// output
	//vec4 bubble = Multiply( pattern, vec4( fresnel + intersection ) );
	//ALBEDO = bubble.rgb + fill * erosionValue;
	//ALPHA = erosionValue * bubble.r + fill + pattern.r * patternTransparency;
	//EMISSION = color.rgb * erosionValue;
	ALBEDO =  pattern.rgb * ( fresnel * colorFresnel ) + ( intersection * colorIntersection );
}

void light() {
	#ifdef USE_LIGHTING
		// diffuse lighting
		vec3 N = normalize(NORMAL);
		vec3 L = LIGHT; // actually a direction
		float lambert = clamp( dot( N, L ), 0.0, 1.0);
		vec3 diffuseLight = lambert * LIGHT_COLOR / PI;

		// specular lighting
		// vec3 V = normalize( VIEW - wPos );
		vec3 H = normalize(L + -V); // Blinn-Phong
		//vec3 R = reflect(-L, N); // Phong
		float light = clamp( dot( H, N ), 0.0, 1.0 ) * float(lambert > 0.0);
		float specularExponent = exp2( gloss * 11.0) + 2.0; // gloss remapping (do this in C# or GDscript so it doesn't run every frame)
		vec3 specularLight = vec3( pow( light, specularExponent ) * gloss * ATTENUATION ); // specular exponent
		specularLight *= LIGHT_COLOR;


		DIFFUSE_LIGHT += diffuseLight;
		SPECULAR_LIGHT += specularLight;
	#else
		// nothing TODO
	#endif
}