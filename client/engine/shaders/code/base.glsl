#pragma language glsl3

//camera uniforms
uniform highp mat4 transformProj;   //projective transformation
uniform highp mat4 transform;       //model transformation
uniform highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying highp vec3 varyingNormal;  //vertex normal for pixel shader
varying highp vec3 varyingTangent; //vertex tangent for pixel shader
varying highp vec3 varyingBitangent; //vertex bi tangent for pixel shader
varying float depth;               //depth

uniform float translucency;

//shader specific defines
#import defines

#ifdef DEPTH_AVAILABLE
uniform Image depthTexture;
#endif



#ifdef PIXEL
vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic);

void effect() {
	vec3 viewVec = normalize(vertexPos - viewPos);

	//outputs
	vec2 distortion = vec2(0.0);
	vec3 color = vec3(0.0);
	vec3 light = vec3(0.0);

	//surface
	vec3 normal = normalize(varyingNormal);
	vec3 tangent = normalize(varyingTangent);
	vec3 bitangent = normalize(varyingBitangent);

	//material
	vec3 albedo = vec3(0.5);
	float alpha = 1.0;
	float roughness = 0.5;
	float metallic = 0.0;
	float ao = 1.0;
	vec3 emission = vec3(0.0);

	//proper backfaces
	if (!gl_FrontFacing) {
		normal = -normal;
	}

#ifdef TANGENT
	mat3 TBN = mat3(tangent, bitangent, normal);
#endif
	
#import pixelMaterial

#ifdef DISCARD
	if (alpha < 0.5) {
		discard;
	}
#endif

#ifdef DITHER
	if (alpha < fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73)) {
		discard;
	}
#endif

#ifndef ALPHA_PASS
	alpha = 1.0;
#endif
	
#import pixel

	//distortion
#ifdef REFRACTIONS_ENABLED
	if (ior != 1.0) {
		//refract and transform back to pixel coord
		vec3 endPoint = vertexPos + refract(viewVec, normal, ior);
		vec4 endPixel = transformProj * vec4(endPoint, 1.0);
		endPixel /= endPixel.w;
		endPixel.xy = endPixel.xy * 0.5 + 0.5;
		
		//uv translation
		distortion = love_PixelCoord.xy / love_ScreenSize.xy - endPixel.xy;
	}
#endif
	
	//fog
#ifdef FOG_ENABLED
	vec4 fogColor = getFog(depth, viewVec, viewPos);
	color = mix(color, fogColor.rgb, fogColor.a);
#endif

#ifdef GAMMA_CORRECTION
	color = pow(color, vec3(1.0 / 2.2));
#endif
	
	//distortion
#ifdef REFRACTIONS_ENABLED
	//to allow distortion blending we use premultiplied alpha blending, which required manual rgb math here
	color *= alpha;
	love_Canvases[1] = vec4(distortion, 0.0, 0.0);
#endif
	
	//depth
#ifdef DEPTH_ENABLED
	love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
#endif
	
	//returns color
#ifdef IS_SHADOW
#ifdef IS_SUN
	love_Canvases[0] = vec4(depth, depth, 0.0, 1.0);
#else
	float dd = length(viewPos - vertexPos.xyz);
	love_Canvases[0] = vec4(dd, dd, 0.0, 1.0);
#endif
#else
	love_Canvases[0] = vec4(color, alpha);
#endif
}
#endif



#ifdef VERTEX


#ifdef INSTANCING
attribute vec3 InstanceRotation0;
attribute vec3 InstanceRotation1;
attribute vec3 InstanceRotation2;
attribute vec3 InstancePosition;
#endif

attribute vec3 VertexNormal;
#ifdef TANGENT
attribute vec4 VertexTangent;
#endif

vec4 position(mat4 _t, vec4 _v) {
	//normal vec transformation
	mat3 normalTransform = mat3(transform);
	
#ifdef INSTANCING
	mat3 instanceRotation = mat3(
		InstanceRotation0.xyz,
		InstanceRotation1.xyz,
		InstanceRotation2.xyz
	);
	
	vertexPos = instanceRotation * VertexPosition.xyz + InstancePosition;
	
	normalTransform = normalTransform * instanceRotation;
#else
	vertexPos = VertexPosition.xyz;
#endif
	
#import vertex
	
	//apply projection matrix
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	//raw normal vector without normal map;
	varyingNormal = normalize(normalTransform * (VertexNormal - vec3(0.5)));
	
#ifdef TANGENT
	varyingTangent = normalize(normalTransform * (VertexTangent.xyz - vec3(0.5)));
	
	//in case the UV is mirrored
	if (VertexTangent.w > 0.5) {
		varyingBitangent = cross(varyingTangent, varyingNormal);
	} else {
		varyingBitangent = cross(varyingNormal, varyingTangent);
	}
#endif
	
	//return the transformed position
	return vPos;
}
#endif