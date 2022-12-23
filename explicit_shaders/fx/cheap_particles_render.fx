#define CHEAP_PARTICLE_CORE_VS
#include "fx/cheap_particle_core.fxh"

#define VERTICES_PER_PARTICLE		4
#define PARTICLE_TEXTURE_WIDTH		128
#define PARTICLE_TEXTURE_HEIGHT		64

#if defined(xenon) || (DX_VERSION == 11)

void DefaultVS(
#if DX_VERSION == 11
	in uint instance_index : SV_InstanceID,
	in uint vertex_index : SV_VertexID,
#else
	in int index : INDEX,
#endif
	out float4	outPosition : SV_Position,
	out float4	outTexcoord : TEXCOORD0,
	out float4  outColor : TEXCOORD1,
	out float3	outColorAdd : TEXCOORD2)
{
#if DX_VERSION == 11
	uint index = (instance_index * 4) + (vertex_index ^ ((vertex_index >> 1) & 1));
#endif

	outColor = float4(0, 0, 0, 0);

    // Determine the vertex index for this particle based on its particle index
	float particleIndex = floor(index * (1.0f / VERTICES_PER_PARTICLE) + (0.5f / VERTICES_PER_PARTICLE));
	float vertexIndex = index - particleIndex * VERTICES_PER_PARTICLE;

	float2 particleCoord;
	
	const float2 k_inverseTextureDimensions = float2(1.0f / PARTICLE_TEXTURE_WIDTH, 1.0f / PARTICLE_TEXTURE_HEIGHT);

	particleCoord.y = floor(particleIndex * k_inverseTextureDimensions.y);
	particleCoord.x = particleIndex - particleCoord.y *  PARTICLE_TEXTURE_WIDTH;

	particleCoord = (particleCoord + 0.5) * k_inverseTextureDimensions;

	// fetch particle data
	float4 positionAndAge = FetchPositionAndAge(particleIndex);

	if (abs(positionAndAge.w) > 1.0)
	{
		// Only transform particle if it's active, otherwise transform to origin:
		outPosition = vs_hiddenFromCompilerNaN;
		outTexcoord = vs_hiddenFromCompilerNaN;
		outColor = vs_hiddenFromCompilerNaN;
		outColorAdd = vs_hiddenFromCompilerNaN.xyz;
	}
	else
	{
		// process active particles

		float4 velocityAndDeltaAge = FetchVelocityAndDeltaAge(particleIndex);
		float3 particlePositionWorld = positionAndAge.xyz;		
		float3 particleToCameraWorld = normalize(particlePositionWorld - vs_view_camera_position);
		
		// move towards camera by a little bit ###ctchou $TODO this percentage should be controlled
		particlePositionWorld -= particleToCameraWorld * 0.01f;

		float4 particleParameters = FetchParticleParameters(particleIndex);
		float particleType = particleParameters.x;
		float illumination = exp2(particleParameters.y * (22/256.0) - 11); // light range approximately between [2^-11, 2^11], gives us about 6.16% brightness steps
		float2 localDX = particleParameters.zw / 63.5f;
				
		float4 sizeConstants = GetTypeData(particleType, TYPE_DATA_SIZE);
		float size = lerp(sizeConstants.x, sizeConstants.y, frac(particleIndex * 0.863182394)); // completely arbitrary multiplier to get terrible "random" value for nearly free
		
		float4 render = GetTypeData(particleType, TYPE_DATA_RENDER);
		float textureIndex = render.x;
		float motionBlurStretchFactor = render.z;
		float textureYScale = render.w;	
		
		localDX *= size;
		
		float speed = length(velocityAndDeltaAge.xyz);
		float stretchScale = max(motionBlurStretchFactor * speed, 1.0f) / speed;
			
		// Basis contains velocity vector, and attempts to face screen (fix me) // ###ctchou $TODO try to set camera_facing component to zero before normalizing.. ?
		float2x3 basis;
		basis[0] = vs_view_camera_right;
		basis[1] = vs_view_camera_up;

		if (textureYScale > 0)
		{
			basis[0] = velocityAndDeltaAge.xyz * stretchScale;
			basis[1] = safe_normalize(cross(basis[0], particleToCameraWorld));	
		}
				
		float2 localPos = GenerateRotatedQuadPoint2D(vertexIndex, float2(0.0f, 0.0f), localDX); 

		float3 positionWorld = particlePositionWorld + mul(localPos, basis);
		outPosition = float4(positionWorld, 1.0f);
		outPosition = mul(outPosition, vs_view_view_projection_matrix);

		//float4 scatterParameters = GetAtmosphereFogOptimizedLUT(
			//vs_atmosphere_fog_table,
			//vs_LUTConstants,
			//vs_fogConstants,
			//vs_view_camera_position,
			//positionWorld.xyz,
			//k_vs_boolean_enable_atm_fog,
			//true);

		float4 color0 = GetTypeData(particleType, TYPE_DATA_COLOR0);
		float fade = sizeConstants.a;
		
		float blend = saturate(fade - abs(fade * positionAndAge.w));
		outColor.rgb = color0.rgb * blend * illumination;
		outColor.a = saturate(color0.a * blend);
		
		//outColor.rgb = outColor.rgb * scatterParameters.a;
		outColorAdd.rgb = float3(0.0, 0.0, 0.0);//scatterParameters.rgb;
		
		outTexcoord.xy = GenerateQuadPoint2D(vertexIndex);
		outTexcoord.y = (outTexcoord.y - 0.5f) * textureYScale + 0.5f;
#if DX_VERSION == 11
		outTexcoord.z = (textureIndex * vs_arrayTextureParameters.x) + vs_arrayTextureParameters.y;
#else		
		outTexcoord.z = textureIndex;
#endif
		outTexcoord.w = 0.0f; // position_and_age.w;	
	}
}

[maxtempreg(4)]
float4 DefaultPS(
	in float4 screenPosition : SV_Position,
	in float4 texcoord : TEXCOORD0,
	in float4 color : TEXCOORD1,
	in float3 colorAdd : TEXCOORD2) : SV_Target0
{
#ifdef xenon
	asm
	{
		tfetch3D	texcoord.xyzw,
					texcoord.xyz,
					ps_renderTexture,
					MagFilter = linear,
					MinFilter = linear,
					MipFilter = linear,
					VolMagFilter = point,
					VolMinFilter = point,
					AnisoFilter = disabled,	// max2to1, // ###ctchou $TODO test anisotropic filtering cost -- could be good for the quality of very motion-blurred particles
					LODBias = -0.5
	};
#elif DX_VERSION == 11
	texcoord = ps_renderTexture.t.SampleBias(ps_renderTexture.s, texcoord.xyz, -0.5);
#endif	

	texcoord.rgba *= color.rgba;
	
	float alpha = texcoord.a;
#ifdef xenon
	alpha /= 32.0f;
#endif	
	return float4((texcoord.rgb  + colorAdd.rgb * texcoord.a) * lerp(ps_view_exposure.x, ps_view_self_illum_exposure.y, texcoord.a), alpha);
}

#else // !defined(xenon)
void DefaultVS(out float4 outPosition : SV_Position) { outPosition = 0.0f; }
float4 DefaultPS() : SV_Target0 { return 0.0f; }
#endif // !defined(xenon)

BEGIN_TECHNIQUE
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(DefaultVS());
		SET_PIXEL_SHADER(DefaultPS());
	}
}