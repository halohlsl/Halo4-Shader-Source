#include "lighting/forge_lightmap.fxh"
#include "forge_lightmap_render_sun_structure_registers.fxh"

static float4 const01 = float4( 0, 1, 0, 0 );

void light_and_untile(
	in int2 vpos, 
	in float3 shadowProjection, 
	uniform bool AOOnly
#if DX_VERSION == 11
	, out float4 result
#endif	
	)
{
#if defined (xenon) || (DX_VERSION == 11)
	int3 unnormTexcoord = 0;
	unnormTexcoord.xy = vpos;
	float4 texel;
#ifdef xenon	
	asm{ 	tfetch3D texel, unnormTexcoord, vs_positionSampler, 
		OffsetZ= 3.0, UseComputedLOD=false, UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true  };
#else
	texel = vs_positionSampler.t.Load(int4(unnormTexcoord.xy,3,0));
#endif
			
	// we're only drawing objects that were drawn to the current shadow buffer bucket. However, because
	// objects may straddle two or more buckets, we'll inevitably pass through parts of the object
	// that lie outside of the current shadow buffer bucket. So, if we see shadow-UV coordinates that are out of range,
	// we don't want to draw anything
	if	(saturate(shadowProjection.x) != shadowProjection.x || saturate(shadowProjection.y) != shadowProjection.y)
	{
		// do nothing
	}
	else
	{	
		// only need one sample
		float max_depth= -0.001f;
		max_depth *= -2.0f;
		max_depth += shadowProjection.z;
				
		float4 shadowSample;
#ifdef xenon		
		asm{ 	tfetch3D shadowSample, shadowProjection.xy, vs_shadowSampler, 
			OffsetZ= 3.0, UseComputedLOD=false, UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point };
#else
		shadowSample = vs_shadowSampler.t.Load(int4(shadowProjection.xy,3,0));
#endif
				
		// sun channel for per-vertex lighting resides in the green color of the fourth texture (offsetZ = 3.0) in the array
		float newLightingValue = step(max_depth.x, shadowSample.r);
		
		if (AOOnly)
		{
			// only darken, so as not to invalidate shadows already properly baked into the objects (unless we're told to overwrite everything)
			if (vs_overwrite || newLightingValue < texel.r)
			{
				// clamp to above zero so that the floating shadow looks right
				texel.r = max(newLightingValue, 1.0 / 64.0f);
			}
		}
		else
		{
			// only darken, so as not to invalidate shadows already properly baked into the objects (unless we're told to overwrite everything)
			if (vs_overwrite || newLightingValue < texel.g)
			{
				// clamp to above zero so that the floating shadow looks right
				texel.g = max(newLightingValue, 1.0 / 64.0f);
			}
		}
	}

#ifdef xenon	
	float linearOffset = dot(unnormTexcoord.xy, float2(1.0f, 1024.0f));
	asm
	{
		alloc export=1
		mad eA, linearOffset, const01, vs_mem_export_stream_constant
		mov eM0, texel
	};
#else
	result = texel;
#endif	
	
#endif
}

void forge_lightmap_sun_structure_ps(
	in float4 screenPosition : SV_Position,
	const in float4 fragment_position_shadow_forward : TEXCOORD0, 
	in SCREEN_POSITION_INPUT(vpos), 
	out float4 outColor: SV_Target0)
{	
	float3 shadowProjection = fragment_position_shadow_forward.xyz;
	
	// we're only drawing objects that were drawn to the current shadow buffer bucket. However, because
	// objects may straddle two or more buckets, we'll inevitably pass through parts of the object
	// that lie outside of the current shadow buffer bucket. So, if we see shadow-UV coordinates that are out of range,
	// we don't want to draw anything
	if	(saturate(shadowProjection.x) != shadowProjection.x || saturate(shadowProjection.y) != shadowProjection.y)
	{
		clip(-1);
		outColor = float4(0.0, 0.0, 0.0, 0.0);	
		return;
	}
	
	float colorValue = sample_percentage_closer_PCF_5x5_block_predicated(shadowProjection, -0.001f);
						
	outColor =  float4(colorValue, 0.0, colorValue, 0.0);
}									

#define BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(vertex_type)						\
void forge_lightmap_sun_per_pixel_##vertex_type##_vs(								\
	in s_##vertex_type##_vertex input,								\
	in s_lightmap_per_pixel input_lightmap,								\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out float4 fragment_position_shadow_forward : TEXCOORD0)					\
{													\
	DecompressPosition(input.position);								\
	fragment_position_shadow_forward = float4(transform_point(input.position, vs_shadow_projection_forward), 1.0);	\
	float2 texcoord = float2(									\
		(input_lightmap.texcoord.x + VS_LIGHT_PACKING_INDEX_HOR) / VS_LIGHT_PACKING_SIZE, 	\
		(input_lightmap.texcoord.y + VS_LIGHT_PACKING_INDEX_VER) / VS_LIGHT_PACKING_SIZE);	\
	out_position = 	float4(										\
		bx2(2 * texcoord.x - VS_TILE_INDEX), -bx2(texcoord.y), 					\
		0.0, 1.0);										\
}

// Build vertex shaders for the per-pixel passes
BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(world);			// forge_lightmap_sun_per_pixel_world_vs
BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(rigid);			// forge_lightmap_sun_per_pixel_rigid_vs
BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(skinned);			// forge_lightmap_sun_per_pixel_skinned_vs
BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(rigid_blendshaped);	// forge_lightmap_sun_per_pixel_rigid_blendshaped_vs
BUILD_FORGE_LIGHTMAP_SUN_PER_PIXEL_VS(skinned_blendshaped);	// forge_lightmap_sun_per_pixel_skinned_blendshaped_vs

BEGIN_TECHNIQUE static_per_pixel
{
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_sun_structure_ps());
	}
	pass world									
	{										
		SET_VERTEX_SHADER(forge_lightmap_sun_per_pixel_world_vs());	
	}										
	pass rigid									
	{										
		SET_VERTEX_SHADER(forge_lightmap_sun_per_pixel_rigid_vs());	
	}										
	pass skinned									
	{										
		SET_VERTEX_SHADER(forge_lightmap_sun_per_pixel_skinned_vs());	
	}										
	pass rigid_blendshaped								
	{										
		SET_VERTEX_SHADER(forge_lightmap_sun_per_pixel_rigid_blendshaped_vs());
	}			
	pass skinned_blendshaped
	{			
		SET_VERTEX_SHADER(forge_lightmap_sun_per_pixel_skinned_blendshaped_vs());
	}
}

#if defined(xenon)
#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(vertex_type)							\
void forge_lightmap_per_vertex_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,												\
	in uint vertexIndex : SV_VertexID)												\
{																					\
	LightmapVertexOutput forgeLightmapOutput;										\
	DecompressPosition(input.position);												\
	ForgeLightmapVS(input.position, input.normal, forgeLightmapOutput);				\
	int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;\
	light_and_untile(int2(offsetVertexIndex % 1024, offsetVertexIndex / 1024),		\
			forgeLightmapOutput.fragment_position_shadow_forward, false);			\
}
#elif DX_VERSION == 11
float4 forge_lightmap_per_vertex_ps(
	in float4 position : SV_Position,
	in float4 color : TEXCOORD0) : SV_Target
{
	return color;
}

#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(vertex_type)							\
void forge_lightmap_per_vertex_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,												\
	in uint vertexIndex : SV_VertexID,												\
	out float4 out_position : SV_Position,											\
	out float4 out_color : TEXCOORD0)												\
{																					\
	LightmapVertexOutput forgeLightmapOutput;										\
	DecompressPosition(input.position);												\
	ForgeLightmapVS(input.position, input.normal, forgeLightmapOutput);				\
	int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;\
	int2 unnormTexCoord = int2(offsetVertexIndex % 1024, offsetVertexIndex / 1024);	\
	light_and_untile(unnormTexCoord, forgeLightmapOutput.fragment_position_shadow_forward, false, out_color);	\
	out_position = float4((unnormTexCoord * vs_screen_scale_offset.xy) + vs_screen_scale_offset.zw, 0, 1);		\
}
#else   // defined(xenon)
// Only Xenon can do the per-vertex lighting using the vertex tfetches
#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(vertex_type)                    						\
void forge_lightmap_per_vertex_##vertex_type##_vs(													\
    in s_##vertex_type##_vertex input,																\
    ISOLATE_OUTPUT out float4 out_position: SV_Position)											\
{																									\
	s_vertex_shader_output output = (s_vertex_shader_output)0;										\
	float4 local_to_world_transform[3];																\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);	\
}
#endif  // defined(xenon)


BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(world);			// forge_lightmap_per_vertex_world_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(rigid);			// forge_lightmap_per_vertex_rigid_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(skinned);			// forge_lightmap_per_vertex_skinned_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(rigid_blendshaped);		// forge_lightmap_per_vertex_rigid_blendshaped_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_VS(skinned_blendshaped);	// forge_lightmap_per_vertex_skinned_blendshaped_vs

BEGIN_TECHNIQUE static_per_vertex
{
#if DX_VERSION == 11
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_per_vertex_ps());
	}
#endif
	pass world									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_world_vs());
	}										
	pass rigid									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_rigid_vs());	
	}										
	pass skinned									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_skinned_vs());	
	}										
	pass rigid_blendshaped								
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_rigid_blendshaped_vs());
	}			
	pass skinned_blendshaped
	{			
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_skinned_blendshaped_vs());
	}
}

#if defined(xenon)
#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(vertex_type)							\
void forge_lightmap_per_vertex_ao_##vertex_type##_vs(								\
	in s_##vertex_type##_vertex input,												\
	in uint vertexIndex : SV_VertexID)												\
{																					\
	LightmapVertexOutput forgeLightmapOutput;										\
	DecompressPosition(input.position);												\
	ForgeLightmapVS(input.position, input.normal, forgeLightmapOutput);				\
	int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;\
	light_and_untile(int2(offsetVertexIndex % 1024, offsetVertexIndex / 1024),		\
			forgeLightmapOutput.fragment_position_shadow_forward, true);			\
}
#elif DX_VERSION == 11
#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(vertex_type)							\
void forge_lightmap_per_vertex_ao_##vertex_type##_vs(								\
	in s_##vertex_type##_vertex input,												\
	in uint vertexIndex : SV_VertexID,												\
	out float4 out_position : SV_Position,											\
	out float4 out_color : TEXCOORD0)												\
{																					\
	LightmapVertexOutput forgeLightmapOutput;										\
	DecompressPosition(input.position);												\
	ForgeLightmapVS(input.position, input.normal, forgeLightmapOutput);				\
	int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;\
	int2 unnormTexCoord = int2(offsetVertexIndex % 1024, offsetVertexIndex / 1024);	\
	light_and_untile(unnormTexCoord, forgeLightmapOutput.fragment_position_shadow_forward, true, out_color);	\
	out_position = float4((unnormTexCoord * vs_screen_scale_offset.xy) + vs_screen_scale_offset.zw, 0, 1);		\
}
#else   // defined(xenon)
// Only Xenon can do the per-vertex lighting using the vertex tfetches
#define BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(vertex_type)                    						\
void forge_lightmap_per_vertex_ao_##vertex_type##_vs(												\
    in s_##vertex_type##_vertex input,																\
    ISOLATE_OUTPUT out float4 out_position: SV_Position)											\
{																									\
	s_vertex_shader_output output = (s_vertex_shader_output)0;										\
	float4 local_to_world_transform[3];																\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);	\
}
#endif  // defined(xenon)

BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(world);				// forge_lightmap_per_vertex_ao_world_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(rigid);				// forge_lightmap_per_vertex_ao_rigid_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(skinned);				// forge_lightmap_per_vertex_ao_skinned_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(rigid_blendshaped);	// forge_lightmap_per_vertex_ao_rigid_blendshaped_vs
BUILD_FORGE_LIGHTMAP_PER_VERTEX_AO_VS(skinned_blendshaped);	// forge_lightmap_per_vertex_ao_skinned_blendshaped_vs

BEGIN_TECHNIQUE static_per_vertex_ao
{
#if DX_VERSION == 11
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_per_vertex_ps());
	}
#endif
	pass world									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_ao_world_vs());	
	}										
	pass rigid									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_ao_rigid_vs());	
	}										
	pass skinned									
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_ao_skinned_vs());	
	}										
	pass rigid_blendshaped								
	{										
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_ao_rigid_blendshaped_vs());
	}			
	pass skinned_blendshaped
	{			
		SET_VERTEX_SHADER(forge_lightmap_per_vertex_ao_skinned_blendshaped_vs());
	}
}