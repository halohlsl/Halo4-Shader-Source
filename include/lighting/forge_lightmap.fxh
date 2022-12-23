#include "lighting/shadows.fxh"
#include "core/core_vertex_types.fxh"
#include "deform.fxh"
#include "forge_lightmap_registers.fxh"

#define		LIGHT_DATA(offset, registers)	(ps_forge_lights[offset].registers)
#define		LIGHT_POSITION				LIGHT_DATA(0, xyz)
#define		LIGHT_DIRECTION				LIGHT_DATA(1, xyz)
#define		LIGHT_COLOR				LIGHT_DATA(2, xyz)
#define		LIGHT_COSINE_CUTOFF_ANGLE 		LIGHT_DATA(3, x)
#define		LIGHT_ANGLE_FALLOFF_RAIO 		LIGHT_DATA(3, y)
#define		LIGHT_ANGLE_FALLOFF_POWER 		LIGHT_DATA(3, z)
#define		LIGHT_FAR_ATTENUATION_END 		LIGHT_DATA(4, y)
#define		LIGHT_FAR_ATTENUATION_RATIO 		LIGHT_DATA(4, z)

#define 	USE_VARIANCE				LIGHT_DATA(0, w)

#define VS_LIGHT_PACKING_INDEX_HOR vs_forge_lightmap_packing_constant.x
#define VS_LIGHT_PACKING_SIZE vs_forge_lightmap_packing_constant.y
#define VS_LIGHT_PACKING_INDEX_VER vs_forge_lightmap_packing_constant.z
#define VS_TILE_INDEX vs_forge_lightmap_packing_constant.w

struct LightmapVertexOutput
{
	float4 fragment_position_shadow_forward : TEXCOORD0;
	float4 fragment_position_shadow_backward : TEXCOORD1;
	float3 normal : NORMAL;
};

struct LightmapSpotlightVertexOutput
{
	float4 fragment_position_shadow_forward : TEXCOORD0;
	float4 fragment_position_shadow_backward : TEXCOORD1;
	float4 original_position : TEXCOORD2;
	float3 normal : NORMAL;
};

////////////////////////////////////////////////////////////////////////////////
/// Forge lightmap pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

void ForgeLightmapVS(in float4 position, in float3 normal, out LightmapVertexOutput output)
{
	output.fragment_position_shadow_forward = float4(transform_point(position, vs_shadow_projection_forward), 1.0);
	output.fragment_position_shadow_backward = float4(transform_point(position, vs_shadow_projection_backward), 1.0);
	output.normal = normalize(transform_vector(normal, vs_local_to_world_transform));
}

#define BUILD_FORGE_LIGHTMAP_VS(vertex_type)								\
void forge_lightmap_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,								\
	in s_lightmap_per_pixel input_lightmap,								\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out LightmapVertexOutput forgeLightmapOutput)							\
{													\
	DecompressPosition(input.position);								\
	ForgeLightmapVS(input.position, input.normal, forgeLightmapOutput);				\
	float2 texcoord = float2(									\
		(input_lightmap.texcoord.x + VS_LIGHT_PACKING_INDEX_HOR) / VS_LIGHT_PACKING_SIZE, 	\
		(input_lightmap.texcoord.y + VS_LIGHT_PACKING_INDEX_VER) / VS_LIGHT_PACKING_SIZE);	\
	out_position = 	float4(										\
		bx2(texcoord.x), -bx2(texcoord.y), 							\
		0.0, 1.0);										\
}

// Build vertex shaders for the forge lightmap passes
BUILD_FORGE_LIGHTMAP_VS(world);				// forge_lightmap_world_vs
BUILD_FORGE_LIGHTMAP_VS(rigid);				// forge_lightmap_rigid_vs
BUILD_FORGE_LIGHTMAP_VS(skinned);			// forge_lightmap_skinned_vs
BUILD_FORGE_LIGHTMAP_VS(rigid_blendshaped);		// forge_lightmap_rigid_blendshaped_vs
BUILD_FORGE_LIGHTMAP_VS(skinned_blendshaped);		// forge_lightmap_skinned_blendshaped_vs

#define TECHNIQUE_VERTEX_SHADERS 						\
pass world									\
{										\
	SET_VERTEX_SHADER(forge_lightmap_world_vs());		\
}										\
pass rigid									\
{										\
	SET_VERTEX_SHADER(forge_lightmap_rigid_vs());		\
}										\
pass skinned									\
{										\
	SET_VERTEX_SHADER(forge_lightmap_skinned_vs());		\
}										\
pass rigid_blendshaped								\
{										\
	SET_VERTEX_SHADER(forge_lightmap_rigid_blendshaped_vs());	\
}										\
pass skinned_blendshaped							\
{										\
	SET_VERTEX_SHADER(forge_lightmap_skinned_blendshaped_vs());	\
}

#define BUILD_FORGE_LIGHTMAP_SUN_VS(vertex_type)							\
void forge_lightmap_sun_##vertex_type##_vs(								\
	in s_##vertex_type##_vertex input,								\
	in s_lightmap_per_pixel input_lightmap,								\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out float4 fragment_position_shadow_forward : TEXCOORD0,					\
	out float3 normal : NORMAL)						\
{													\
	DecompressPosition(input.position);								\
	fragment_position_shadow_forward = float4(transform_point(input.position, vs_shadow_projection_forward), 1.0);	\
	normal = normalize(transform_vector(input.normal, vs_local_to_world_transform));	\
	float2 texcoord = float2(									\
		(input_lightmap.texcoord.x + VS_LIGHT_PACKING_INDEX_HOR) / VS_LIGHT_PACKING_SIZE, 	\
		(input_lightmap.texcoord.y + VS_LIGHT_PACKING_INDEX_VER) / VS_LIGHT_PACKING_SIZE);	\
	out_position = 	float4(										\
		bx2(2 * texcoord.x - VS_TILE_INDEX), -bx2(texcoord.y), 					\
		0.0, 1.0);										\
}

// Build vertex shaders for the forge sun lightmap passes
BUILD_FORGE_LIGHTMAP_SUN_VS(world);			// forge_lightmap_sun_world_vs
BUILD_FORGE_LIGHTMAP_SUN_VS(rigid);			// forge_lightmap_sun_rigid_vs
BUILD_FORGE_LIGHTMAP_SUN_VS(skinned);			// forge_lightmap_sun_skinned_vs
BUILD_FORGE_LIGHTMAP_SUN_VS(rigid_blendshaped);		// forge_lightmap_sun_rigid_blendshaped_vs
BUILD_FORGE_LIGHTMAP_SUN_VS(skinned_blendshaped);	// forge_lightmap_sun_skinned_blendshaped_vs

#define TECHNIQUE_SUN_VERTEX_SHADERS							\
pass world										\
{											\
	SET_VERTEX_SHADER(forge_lightmap_sun_world_vs());			\
}											\
pass rigid										\
{											\
	SET_VERTEX_SHADER(forge_lightmap_sun_rigid_vs());			\
}											\
pass skinned										\
{											\
	SET_VERTEX_SHADER(forge_lightmap_sun_skinned_vs());			\
}											\
pass rigid_blendshaped									\
{											\
	SET_VERTEX_SHADER(forge_lightmap_sun_rigid_blendshaped_vs());	\
}											\
pass skinned_blendshaped								\
{											\
	SET_VERTEX_SHADER(forge_lightmap_sun_skinned_blendshaped_vs());	\
}