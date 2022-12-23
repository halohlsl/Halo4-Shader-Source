#if !defined(__PARTICLE_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __PARTICLE_PARAMETERS_FXH

#include "fx/fx_parameters.fxh"
#endif

///////////////////////////////////////////
// vertex shader engine-supplied parameters

#ifndef DEFINED_PARTICLE_PARAMETERS_STRUCTS
#define DEFINED_PARTICLE_PARAMETERS_STRUCTS

#define k_maxMeshVariants 15

// These structures are for support of mesh variants on particle models.  They need to match the declaration of:
// c_particle_model_definition::s_gpu_variant_data
struct MeshVariantDefinition
{
	float4 m_data;
#define m_meshVariantStartIndex m_data.x
#define m_meshVariantEndIndex m_data.y
};

struct MeshVariantList
{
#if DX_VERSION == 9
	PADDED(int,2,m_meshVariantList_count_maxSize)
#elif DX_VERSION == 11
	PADDED(float,2,m_meshVariantList_count_maxSize)
#endif
	MeshVariantDefinition m_meshVariants[k_maxMeshVariants];
#define m_meshVariantCount m_meshVariantList_count_maxSize.x
#define m_meshVariantMaxSize m_meshVariantList_count_maxSize.y
};

#define CUSTOM_VERT_SET_COUNT 5
struct Fade
{
	PADDED(float,4,nearRange_nearCutoff_edgeRange_edgeCutoff)
	PADDED(float,2,farRange_farCutoff)
#ifndef DEFINE_CPP_CONSTANTS		
#define nearRange nearRange_nearCutoff_edgeRange_edgeCutoff.x
#define nearCutoff nearRange_nearCutoff_edgeRange_edgeCutoff.y
#define edgeRange nearRange_nearCutoff_edgeRange_edgeCutoff.z
#define edgeCutoff nearRange_nearCutoff_edgeRange_edgeCutoff.w
#define farRange farRange_farCutoff.x
#define farCutoff farRange_farCutoff.y
#endif
};
struct CustomVerts
{
	float4 customVertex0; // pack verts 0,1 here
	float4 customVertex1; // pack verts 1,2 here
};
struct RenderState
{
	PADDED(float,3,flags_main_appearance_animation)
	PADDED(float,2,firstPerson_fadeDepthMultiplier)
	PADDED(float,2,curvature_cameraOffset)
	PADDED(float,2,uvScrollRate)
	PADDED(float,1,gameTime)
	PADDED(float,1,billboardType)
	PADDED(float,1,vertexCount)
	Fade fade;
	CustomVerts customVerts[CUSTOM_VERT_SET_COUNT];	
#ifndef DEFINE_CPP_CONSTANTS		
#define mainFlags flags_main_appearance_animation.x
#define appearanceFlags flags_main_appearance_animation.y
#define animationFlags flags_main_appearance_animation.z
#endif
};
#define eAF_randomlyFlipU				0 //_particle_randomly_flip_u_bit
#define eAF_randomlyFlipV				1 //_particle_randomly_flip_v_bit
#define eAF_randomStartingRotation		2 //_particle_random_starting_rotation_bit
#define eAF_tintFromLightmap			3 //_particle_tint_from_lightmap_bit
#define eAF_tintFromDiffuseTexture		4 //_particle_tint_from_diffuse_texture_bit
#define eAF_sourceBitmapVertical		5 //_particle_source_bitmap_vertical_bit
#define eAF_intensityAffectsAlpha		6 //_particle_intensity_affects_alpha_bit
#define eAF_fadeNearEdge				7 //_particle_fade_near_edge_bit
#define eAF_motionBlur					8 //_particle_motion_blur_bit
#define eAF_doubleSided					9 //_particle_double_sided_bit
#define eAF_lowRes						10
#define eAF_lowResTightMask				11
#define eAF_neverKillVertices			12
#define eAF_velocityRelativeToCamera 13
#define eAF_fogged						13//_particle_fogged_bit
#define eAF_lightmapLit					14 //_particle_lightmap_lit_bit
#define eAF_depthFadeActive				15 //_particle_depth_fade_active_bit
#define eAF_distortionActive			16 //_particle_distortion_active_bit
#define eAF_ldrOnly						17 //_particle_ldr_only_bit
#define eAF_isParticleModel				18 //_particle_is_particle_model_bit

#endif

#define vs_alpha_blend_mode_register vs_alpha_blend_mode

#if DX_VERSION == 9

// 16 slots
DECLARE_PARAMETER(MeshVariantList, vsMeshVariantList, c64);

DECLARE_PARAMETER(RenderState, vsRenderState, c80);

//DECLARE_PARAMETER(float4,	vs_alpha_blend_mode_register,	c16);

DECLARE_PARAMETER(float3x4,	vs_emitter_to_world_matrix,		c33);
DECLARE_PARAMETER(float4,	vs_sprite_offset_and_scale,		c63);

DECLARE_PARAMETER(float3, vs_cameraVelocity, c62);

// vs lighting
DECLARE_PARAMETER(float3,	vsLightingBrightDirection,		c252);
DECLARE_PARAMETER(float3,	vsLightingBrightColor,			c253);
DECLARE_PARAMETER(float3,	vsLightingDarkColor,			c254);
DECLARE_PARAMETER(float3,	vsLightingAmbient,				c255);
// ps lighting
DECLARE_PARAMETER(float3,	psLightingBrightDirection,		c204);
DECLARE_PARAMETER(float3,	psLightingBrightColor,			c205);
DECLARE_PARAMETER(float3,	psLightingDarkColor,			c206);
DECLARE_PARAMETER(float3,	psLightingAmbient,				c207);

DECLARE_PARAMETER(float2, psTintFactor, c208);

DECLARE_PARAMETER(bool, psDepthFadeEnabled, b100);
DECLARE_PARAMETER(bool, psBlackOrWhitePointEnabled, b101);
DECLARE_PARAMETER(bool, psSphereWarpEnabled, b102);
DECLARE_PARAMETER(bool, psNewSchoolFrameIndex, b103);

// sprite list
// These structures are for support of texture animation.  They need to match the declaration of:
// c_particle_definition::s_gpu_data.m_frames
DECLARE_PARAMETER(int2,		vs_sprite_list_count_and_max,	c40);
DECLARE_PARAMETER(float4,	vs_sprite_list_sprites[15],		c41);
// end sprite list

#elif DX_VERSION == 11

#include "raw_particle_state.fxh"

CBUFFER_BEGIN(ParticleParametersVS)
	CBUFFER_CONST(ParticleParametersVS,			RenderState, 		vsRenderState, 						k_vs_particle_parameters_render_state)
	CBUFFER_CONST(ParticleParametersVS,			float3x4,			vs_emitter_to_world_matrix,			k_vs_particle_parameters_emitter_to_world_matrix)
	CBUFFER_CONST(ParticleParametersVS,			float,				vs_emitter_to_world_matrix_pad,		k_vs_particle_parameters_emitter_to_world_matrix_pad)
	CBUFFER_CONST(ParticleParametersVS,			float4,				vs_sprite_offset_and_scale,			k_vs_particle_parameters_sprite_offset_and_scale)
	CBUFFER_CONST(ParticleParametersVS,			float3, 			vs_cameraVelocity, 					k_vs_particle_parameters_camera_velocity)
	CBUFFER_CONST(ParticleParametersVS,			float, 				vs_cameraVelocity_pad, 				k_vs_particle_parameters_camera_velocity_pad)
	CBUFFER_CONST(ParticleParametersVS,			float3,				vsLightingBrightDirection,			k_vs_particle_parameters_lighting_bright_direction)
	CBUFFER_CONST(ParticleParametersVS,			float,				vsLightingBrightDirection_pad,		k_vs_particle_parameters_lighting_bright_direction_pad)
	CBUFFER_CONST(ParticleParametersVS,			float3,				vsLightingBrightColor,				k_vs_particle_parameters_lighting_bright_color)
	CBUFFER_CONST(ParticleParametersVS,			float,				vsLightingBrightColor_pad,			k_vs_particle_parameters_lighting_bright_color_pad)
	CBUFFER_CONST(ParticleParametersVS,			float3,				vsLightingDarkColor,				k_vs_particle_parameters_lighting_dark_color)
	CBUFFER_CONST(ParticleParametersVS,			float,				vsLightingDarkColor_pad,			k_vs_particle_parameters_lighting_dark_color_pad)
	CBUFFER_CONST(ParticleParametersVS,			float3,				vsLightingAmbient,					k_vs_particle_parameters_lighting_ambient)
	CBUFFER_CONST(ParticleParametersVS,			float,				vsLightingAmbient_pad,				k_vs_particle_parameters_lighting_ambient_pad)
	CBUFFER_CONST(ParticleParametersVS,			float2,				vs_sprite_list_count_and_max,		k_vs_particle_parameters_sprite_list_count_and_max)
	CBUFFER_CONST(ParticleParametersVS,			float2,				vs_sprite_list_count_and_max_pad,	k_vs_particle_parameters_sprite_list_count_and_max_pad)
	CBUFFER_CONST_ARRAY(ParticleParametersVS,	float4,				vs_sprite_list_sprites, [15],		k_vs_particle_parameters_sprite_list_sprites)
CBUFFER_END

CBUFFER_BEGIN(ParticleParametersMeshVS)
	CBUFFER_CONST(ParticleParametersMeshVS,		MeshVariantList, 	vsMeshVariantList, 					k_vs_particle_parameters_mesh_variant_list)
CBUFFER_END

CBUFFER_BEGIN(ParticleParametersPS)
	CBUFFER_CONST(ParticleParametersPS,			float3,				psLightingBrightDirection,			k_ps_particle_parameters_lighting_bright_direction)
	CBUFFER_CONST(ParticleParametersPS,			float,				psLightingBrightDirection_pad,		k_ps_particle_parameters_lighting_bright_direction_pad)
	CBUFFER_CONST(ParticleParametersPS,			float3,				psLightingBrightColor,				k_ps_particle_parameters_lighting_bright_color)
	CBUFFER_CONST(ParticleParametersPS,			float,				psLightingBrightColor_pad,			k_ps_particle_parameters_lighting_bright_color_pad)
	CBUFFER_CONST(ParticleParametersPS,			float3,				psLightingDarkColor,				k_ps_particle_parameters_lighting_dark_color)
	CBUFFER_CONST(ParticleParametersPS,			float,				psLightingDarkColor_pad,			k_ps_particle_parameters_lighting_dark_color_pad)
	CBUFFER_CONST(ParticleParametersPS,			float3,				psLightingAmbient,					k_ps_particle_parameters_lighting_ambient)
	CBUFFER_CONST(ParticleParametersPS,			float,				psLightingAmbient_pad,				k_ps_particle_parameters_lighting_ambient_pad)
	CBUFFER_CONST(ParticleParametersPS,			float2, 			psTintFactor, 						k_ps_particle_parameters_tint_factor)
	CBUFFER_CONST(ParticleParametersPS,			float2, 			psTintFactor_pad,					k_ps_particle_parameters_tint_factor_pad)
	CBUFFER_CONST(ParticleParametersPS,			bool, 				psDepthFadeEnabled, 				k_ps_particle_parameters_bool_depth_fade_enabled)
	CBUFFER_CONST(ParticleParametersPS,			bool, 				psBlackOrWhitePointEnabled, 		k_ps_particle_parameters_bool_black_or_white_point_enabled)
	CBUFFER_CONST(ParticleParametersPS,			bool, 				psSphereWarpEnabled, 				k_ps_particle_parameters_bool_sphere_warp_enabled)
	CBUFFER_CONST(ParticleParametersPS,			bool, 				psNewSchoolFrameIndex, 				k_ps_particle_parameters_bool_new_school_frame_index)
CBUFFER_END

STRUCTURED_BUFFER(vs_particle_state_buffer,			k_vs_particle_state_buffer,			s_raw_particle_state,	16)
BYTE_ADDRESS_BUFFER(mesh_vertices,					k_vs_mesh_vertices, 										17)

#endif

#endif 	// !defined(__PARTICLE_PARAMETERS_FXH)