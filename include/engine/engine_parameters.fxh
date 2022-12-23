#if !defined(__ENGINE_PARAMETERS_FXH)

#ifndef DEFINE_CPP_CONSTANTS
#define __ENGINE_PARAMETERS_FXH

#ifndef INCLUDED_FROM_C_SHADERS
#include "core/core_parameters.fxh"
#endif

#endif

#if DX_VERSION == 9

///////////////////////////////////////////
// vertex shader engine-supplied parameters

// changes with each frame	(c8 - c12)
DECLARE_PARAMETER_SEMANTIC(	float4,		vs_time,						Time,									c8);

// changes with each view	(c0 - c7)
DECLARE_PARAMETER_SEMANTIC(	float4x4,	vs_view_view_projection_matrix,	ViewProjectionTranspose,				c0);
DECLARE_PARAMETER_SEMANTIC(	float4x4,	vs_view_camera_to_world_matrix,	ViewInverseTranspose,					c4);
DECLARE_PARAMETER_OVERLAY(	float3,		vs_view_camera_right,			vs_view_camera_to_world_matrix[0].xyz,	c4);
DECLARE_PARAMETER_OVERLAY(	float3,		vs_view_camera_up,				vs_view_camera_to_world_matrix[1].xyz,	c5);
DECLARE_PARAMETER_OVERLAY(	float3,		vs_view_camera_backward,		vs_view_camera_to_world_matrix[2].xyz,	c6);
DECLARE_PARAMETER_OVERLAY(	float3,		vs_view_camera_position,		vs_view_camera_to_world_matrix[3].xyz,	c7);

// changes with each pass	(c12 - c12)

// changes with each bsp	(c15 - c15)

DECLARE_PARAMETER(			sampler,	vs_bsp_lightprobe_data,													s0);
DECLARE_PARAMETER(			sampler,	vs_bsp_lightprobe_ao_data,											s1);

// changes with each node	(c16 - c16)

// changes with each model	(c16 - c225)
DECLARE_PARAMETER_SEMANTIC(	float4,		vs_model_world_matrix[3],		World,									c16);
DECLARE_PARAMETER(			float4,		vs_previous_model_world_matrix[3],										c20);
#if !defined(EXCLUDE_MODEL_MATRICES)

#if defined(USE_VERTEX_STREAM_SKINNING)

DECLARE_PARAMETER(			sampler,	vs_skinningMatrixStream,												vf5);
DECLARE_PARAMETER(			sampler,	vs_previousSkinningMatrixStream,										vf6);

DECLARE_PARAMETER(			float4,		vs_skinningCompressionScale,											c28);
DECLARE_PARAMETER(			float4,		vs_skinningCompressionOffset,											c29);
DECLARE_PARAMETER(			float4,		vs_previousSkinningCompressionScale,									c30);
DECLARE_PARAMETER(			float4,		vs_previousSkinningCompressionOffset,									c31);

DECLARE_PARAMETER(			float4x4, 	vs_previousViewProjectionMatrix,										c24);

// changes with each bsp (overloaded against vs_model_skinning_matrices below between platforms)
DECLARE_PARAMETER(			float4,		vs_bsp_lightmap_compress_constant,										c32)= float4(0,0,0,0);

#else

DECLARE_PARAMETER(			float4,		vs_model_skinning_matrices[70][3],										c16);
#endif
#endif // !defined(EXCLUDE_MODEL_MATRICES)

// changes with each mesh	(c12 - c15)
DECLARE_PARAMETER(			float4,		vs_material_blend_constant,			 									c9)= float4(0,1,0,0);
DECLARE_PARAMETER(			float4,		vs_mesh_position_compression_scale, 									c12)= (float4)1;
DECLARE_PARAMETER(			float4,		vs_mesh_position_compression_offset, 									c13)= (float4)0;
DECLARE_PARAMETER(			float4,		vs_mesh_uv_compression_scale_offset, 									c14)= float4(1,1,0,0);
DECLARE_PARAMETER(			float4,		vs_mesh_lightmap_compress_constant,									c15)= float4(0,0,0,0);

DECLARE_PARAMETER(			bool,		s_atmosphere_fog_light_enable,											b126) = false;
DECLARE_PARAMETER(			bool,		s_atmosphere_fog_enable,												b127) = true;
DECLARE_PARAMETER(			sampler2D,	vs_atmosphere_fog_table,												s2);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_0,												c232);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_1,												c233);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_2,												c234);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_3,												c235);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_4,												c236);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_5,												c237);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_6,												c238);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_7,												c239);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_8,												c240);
DECLARE_PARAMETER(			float4,		s_atmosphere_constant_9,												c241);


DECLARE_PARAMETER(			float4,		vs_analytical_light_direction,											c228);
DECLARE_PARAMETER(			float4,		vs_analytical_light_intensity,											c229);
DECLARE_PARAMETER(			float4,		vs_forge_lightmap_packing_constant,										c230);

DECLARE_PARAMETER(			float4,		vs_material_shader_parameters[4],										c240);

DECLARE_PARAMETER(			bool,		vs_render_rigid_imposter,												b24);
DECLARE_PARAMETER(			bool,		vs_material_shader_bool_parameters[8],									b40);
DECLARE_PARAMETER(			float4,		vs_floating_shadow_inverse_frustum_transform[3],						c236);

// Don't think these are actually used but left for compatibility with D3D9 code
DECLARE_PARAMETER(	float4,		v_lighting_constant_0,					c242);
DECLARE_PARAMETER(	float4,		v_lighting_constant_1,					c243);
DECLARE_PARAMETER(	float4,		v_lighting_constant_2,					c244);
DECLARE_PARAMETER(	float4,		v_lighting_constant_3,					c245);


//////////////////////////////////////////
// pixel shader engine-supplied parameters

// changes with each frame	(c0 - c31)
DECLARE_PARAMETER_SEMANTIC(	float4,		ps_time,						Time,									c1);

// changes with each view	(c32 - c63)
DECLARE_PARAMETER(			float4,		ps_view_exposure, 														c0);

DECLARE_PARAMETER_SEMANTIC(	float4x4,	ps_camera_to_world_matrix,		ViewInverseTranspose,					c4);
DECLARE_PARAMETER(			float3,		ps_camera_right,														c4);
DECLARE_PARAMETER(			float3,		ps_camera_up,															c5);
DECLARE_PARAMETER(			float3,		ps_camera_backward,														c6);
DECLARE_PARAMETER(			float3,		ps_camera_position,														c7);

DECLARE_PARAMETER(			float4,		ps_shadow_direction,													c10);
DECLARE_PARAMETER(			float4,		ps_analytical_light_direction,											c11);
DECLARE_PARAMETER(			float4,		ps_constant_shadow_alpha,												c11);
DECLARE_PARAMETER(			float4, 	ps_view_self_illum_exposure,											c12);

DECLARE_PARAMETER(			float4,		ps_textureSize,															c14);

DECLARE_PARAMETER(			float3x3,	ps_worldspace_normal_axis,												c64);

DECLARE_PARAMETER(			sampler,	ps_view_albedo,															s12);
DECLARE_PARAMETER(			sampler,	ps_view_normal,															s13);
DECLARE_PARAMETER(			sampler,	ps_view_shadow_mask,													s14);
DECLARE_PARAMETER(			sampler, 	ps_shadow_depth_map,													s14);
DECLARE_PARAMETER(			sampler, 	ps_dynamic_light_texture,												s11);
DECLARE_PARAMETER(			sampler, 	ps_dynamic_light_texture_cube,											s11);

DECLARE_PARAMETER(			float4,		ps_dynamic_lights[5],													c18);
DECLARE_PARAMETER(			float4x3,	ps_dynamic_light_gobo_rotation,											c23);
DECLARE_PARAMETER(			bool,		ps_dynamic_light_shadowing,												b13) = false;
DECLARE_PARAMETER(			bool,		ps_dynamic_light_physically_correct,									b14) = false;
DECLARE_PARAMETER(			bool,		ps_dynamic_light_gobo,													b15) = false;

DECLARE_PARAMETER(			float4,		ps_tiling_vpos_offset,													c108);		// code owns these, so needs to be in a block of 4
DECLARE_PARAMETER(			float4,		ps_tiling_resolvetexture_xform,											c109);
DECLARE_PARAMETER(			float4,		ps_tiling_reserved1,													c110);
DECLARE_PARAMETER(			float4,		ps_tiling_reserved2,													c111);


// changes with each pass	(c64 - c95)


// changes with each bsp	(c96 - c127)
DECLARE_PARAMETER(			float4,		ps_bsp_lightmap_compress_constant_1,									c96);
DECLARE_PARAMETER(			float4,		ps_bsp_lightmap_compress_constant_2,									c97);

#if defined(xenon)
DECLARE_PARAMETER(			float4,		ps_bsp_lightmap_scale_constants,										c220);
#endif

DECLARE_PARAMETER(			bool,		ps_boolean_using_floating_sun,											b116) = false;
DECLARE_PARAMETER(			bool,		ps_boolean_using_analytic_light,										b117) = true;
DECLARE_PARAMETER(			bool,		ps_boolean_using_analytic_light_gobo,									b118) = true;
DECLARE_PARAMETER(			bool,		ps_boolean_using_static_lightmap_only,									b119) = false;
DECLARE_PARAMETER(			bool,		ps_bsp_lightmap_use_error,												b124) = false;
DECLARE_PARAMETER(			bool,		ps_bsp_boolean_enable_sharpened_falloff,								b125) = true;

#if defined(xenon)
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_dir_and_bandwidth,									s15);
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_hdr_color,											s16);
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_hybrid_overlay_macro,									s17);
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_hybrid_overlay_micro,									s18);
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_hybrid_refinement,									s19);
DECLARE_PARAMETER(			sampler,	ps_lightmap_sharpen_falloff,											s20);
DECLARE_PARAMETER(			sampler,	ps_cloud_texture,														s21);
DECLARE_PARAMETER(			sampler,	ps_bsp_lightprobe_analytic,												s22);
#endif

// changes with each model	(c136 - c159)
DECLARE_PARAMETER(			float4,		ps_model_sh_lighting[8],												c136);
DECLARE_PARAMETER(			float4,		ps_model_vmf_lighting[4],												c144);
DECLARE_PARAMETER(			float4,		ps_lighting_constants[14],												c144);
DECLARE_PARAMETER(			float4x3,   ps_light_rotation,                       								c151);
DECLARE_PARAMETER(			float3x3,   ps_shadow_rotation,                       								c154);
DECLARE_PARAMETER(			float4,   	ps_forge_lightmap_packing_constant,   									c155);
DECLARE_PARAMETER(			float4,   	ps_forge_lightmap_compress_constant,              						c156);

// changes with each mesh	(c160 - c192)
DECLARE_PARAMETER(			float4,		ps_material_blend_constant,			 									c9)= float4(0,1,0,0);

// changes with each shader
DECLARE_PARAMETER(			float4,		ps_dynamic_cubemap_blend,												c159);

// hack shader parameters
DECLARE_PARAMETER(			float4,		ps_material_shader_parameters[24],										c160);
DECLARE_PARAMETER(			float4,		ps_material_shader_transforms[12],										c184);
DECLARE_PARAMETER(			float4,		ps_material_object_parameters[4],										c196);
DECLARE_PARAMETER(			float4,		ps_material_generic_parameters[4],										c200);
DECLARE_PARAMETER(			bool,		ps_material_shader_bool_parameters[32],									b64);

DECLARE_PARAMETER(			float4,		ps_floating_shadow_light_direction,										c224);
DECLARE_PARAMETER(			float4,		ps_floating_shadow_light_intensity,										c225);
DECLARE_PARAMETER(			float4,		ps_static_floating_shadow_sharpening,									c226);
DECLARE_PARAMETER(			float4,		ps_cloud_constant,														c209);
DECLARE_PARAMETER(			float4,		ps_analytic_light_position,												c212);
DECLARE_PARAMETER(			float4,		ps_analytic_light_intensity,											c213);
DECLARE_PARAMETER(			float4,		ps_analytic_light_gobo_rotation_matrix_0,								c214);
DECLARE_PARAMETER(			float4,		ps_analytic_light_gobo_rotation_matrix_1,								c215);
DECLARE_PARAMETER(			float4,		ps_analytic_light_gobo_rotation_matrix_2,								c216);

#if defined(xenon)
DECLARE_PARAMETER(			float4,		ps_debug_ambient_intensity,												c232);
#endif

#elif DX_VERSION == 11

CBUFFER_BEGIN(EngineFrameVS)
	CBUFFER_CONST(EngineFrameVS,				float4,		vs_time,								_vs_frame_time)
CBUFFER_END	
		
CBUFFER_BEGIN(EngineViewVS)		
	CBUFFER_CONST(EngineViewVS,				float4x4,	vs_view_view_projection_matrix,			_vs_view_view_projection_matrix)
	CBUFFER_CONST(EngineViewVS,				float4x4,	vs_view_camera_to_world_matrix,			_vs_view_camera_to_world_matrix)	
	CBUFFER_CONST(EngineViewVS,				float4x4,	vs_previousViewProjectionMatrix,		_vs_view_previous_view_projection_matrix)
	CBUFFER_CONST(EngineViewVS,				float4,		vs_analytical_light_direction,			k_vs_analytical_light_direction)
	CBUFFER_CONST(EngineViewVS,				float4,		vs_analytical_light_intensity,			k_vs_analytical_light_intensity)
	CBUFFER_CONST(EngineViewVS,				float4,		vs_clip_plane,							k_vs_clip_plane)
CBUFFER_END

SHADER_CONST_ALIAS(EngineViewVS,	float3,		vs_view_camera_right,		vs_view_camera_to_world_matrix._m00_m10_m20,	_vs_view_camera_right,		_vs_view_camera_to_world_matrix, 0)
SHADER_CONST_ALIAS(EngineViewVS,	float3,		vs_view_camera_up,			vs_view_camera_to_world_matrix._m01_m11_m21,	_vs_view_camera_up,			_vs_view_camera_to_world_matrix, 16)
SHADER_CONST_ALIAS(EngineViewVS,	float3,		vs_view_camera_backward,	vs_view_camera_to_world_matrix._m02_m12_m22,	_vs_view_camera_backward,	_vs_view_camera_to_world_matrix, 32)
SHADER_CONST_ALIAS(EngineViewVS,	float3,		vs_view_camera_position,	vs_view_camera_to_world_matrix._m03_m13_m23,	_vs_view_camera_position,	_vs_view_camera_to_world_matrix, 48)

CBUFFER_BEGIN(EngineBSPVS)
	CBUFFER_CONST(EngineBSPVS,				float4,		vs_bsp_lightmap_compress_constant,		_vs_bsp_lightmap_compress_constant)
CBUFFER_END	
	
CBUFFER_BEGIN(EngineNodeVS)	
	CBUFFER_CONST(EngineNodeVS,				float4,		vs_skinningCompressionScale,			_vs_skinning_compression_scale)
	CBUFFER_CONST(EngineNodeVS,				float4,		vs_skinningCompressionOffset,			_vs_skinning_compression_offset)
	CBUFFER_CONST(EngineNodeVS,				float4,		vs_previousSkinningCompressionScale,	_vs_previous_skinning_compression_scale)
	CBUFFER_CONST(EngineNodeVS,				float4,		vs_previousSkinningCompressionOffset,	_vs_previous_skinning_compression_offset)
CBUFFER_END

CBUFFER_BEGIN_FIXED(EngineSkinningVS, 10)
	CBUFFER_CONST_ARRAY(EngineSkinningVS,	float4,		vs_model_skinning_matrices, [70][3],	_vs_model_skinning_matrices)
CBUFFER_END

#define _MODEL_WORLD_VALUE { vs_model_skinning_matrices[0][0], vs_model_skinning_matrices[0][1], vs_model_skinning_matrices[0][2] }
#define _PREV_MODEL_WORLD_VALUE { vs_model_skinning_matrices[1][0], vs_model_skinning_matrices[1][1], vs_model_skinning_matrices[1][2] }
SHADER_CONST_ALIAS(EngineSkinningVS,	float4,		vs_model_world_matrix[3], 			_MODEL_WORLD_VALUE,				_vs_model_world_matrix,				_vs_model_skinning_matrices,0)
SHADER_CONST_ALIAS(EngineSkinningVS,	float4,		vs_previous_model_world_matrix[3], 	_PREV_MODEL_WORLD_VALUE,		_vs_previous_model_world_matrix,	_vs_model_skinning_matrices,48)

CBUFFER_BEGIN(EngineModelVS)
	CBUFFER_CONST(EngineModelVS,				float4,		vs_material_blend_constant,				_vs_material_blend_constant)
	CBUFFER_CONST_ARRAY(EngineModelVS,		float4,		vs_floating_shadow_inverse_frustum_transform, [3], _vs_floating_shadow_inverse_frustum_transform)
CBUFFER_END

CBUFFER_BEGIN(EngineForgeLightmapVS)
	CBUFFER_CONST(EngineForgeLightmapVS,		float4,		vs_forge_lightmap_packing_constant,		_vs_forge_lightmap_packing_constant)
CBUFFER_END

CBUFFER_BEGIN(EngineMeshVS)
	CBUFFER_CONST(EngineMeshVS,				float4,		vs_mesh_lightmap_compress_constant,		_vs_mesh_lightmap_compress_constant)
	CBUFFER_CONST(EngineMeshVS,				bool,		vs_render_rigid_imposter,				k_bool_render_rigid_imposter)
CBUFFER_END

CBUFFER_BEGIN_FIXED(EngineCompressionInfoVS, 11)
	CBUFFER_CONST(EngineCompressionInfoVS,	float4,		vs_mesh_position_compression_scale,		_vs_mesh_position_compression_scale)
	CBUFFER_CONST(EngineCompressionInfoVS,	float4,		vs_mesh_position_compression_offset,	_vs_mesh_position_compression_offset)
	CBUFFER_CONST(EngineCompressionInfoVS,	float4,		vs_mesh_uv_compression_scale_offset,	_vs_mesh_uv_compression_scale_offset)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D_ARRAY,	vs_bsp_lightprobe_data,		_vs_bsp_lightprobe_data,	0)
VERTEX_TEXTURE_AND_SAMPLER(_2D_ARRAY,	vs_bsp_lightprobe_ao_data,	_vs_bsp_lightprobe_ao_data,	1)


CBUFFER_BEGIN(EngineFramePS)
	CBUFFER_CONST(EngineFramePS,				float4,		ps_time,								_ps_frame_time)
CBUFFER_END

CBUFFER_BEGIN(EngineViewPS)
	CBUFFER_CONST(EngineViewPS,				float4x4,	ps_camera_to_world_matrix,				_ps_view_camera_to_world_matrix)
	CBUFFER_CONST(EngineViewPS,				float3x3,	ps_worldspace_normal_axis,				_ps_view_worldspace_normal_axis)
	CBUFFER_CONST(EngineViewPS,				float,		ps_worldspace_normal_axis_pad,			_ps_view_worldspace_normal_axis_pad)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_view_exposure,						_ps_view_exposure)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_view_self_illum_exposure,			_ps_view_self_illum_exposure)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_shadow_direction,					k_ps_shadow_dir)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_analytical_light_direction,			k_ps_analytical_light_direction)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_constant_shadow_alpha,				k_ps_shadow_alpha)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_tiling_vpos_offset,					k_tiling_vpos_offset)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_tiling_resolvetexture_xform,			k_tiling_resolvetexture_xform)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_tiling_reserved1,					k_tiling_reserved1)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_tiling_reserved2,					k_tiling_reserved2)
	CBUFFER_CONST(EngineViewPS,				float4,		ps_debug_ambient_intensity,				k_ps_debug_ambient_intensity)
CBUFFER_END

#define ps_alt_exposure ps_view_self_illum_exposure

CBUFFER_BEGIN(EngineAtmosphere)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_0,				k_atmosphere_constant_0)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_1,				k_atmosphere_constant_1)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_2,				k_atmosphere_constant_2)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_3,				k_atmosphere_constant_3)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_4,				k_atmosphere_constant_4)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_5,				k_atmosphere_constant_5)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_6,				k_atmosphere_constant_6)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_7,				k_atmosphere_constant_7)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_8,				k_atmosphere_constant_8)
	CBUFFER_CONST(EngineAtmosphere,			float4,		s_atmosphere_constant_9,				k_atmosphere_constant_9)
CBUFFER_END

CBUFFER_BEGIN(EngineAtmosphereFlags)
	CBUFFER_CONST(EngineAtmosphereFlags,	bool,		s_atmosphere_fog_light_enable,			k_atmosphere_fog_light_enable)
	CBUFFER_CONST(EngineAtmosphereFlags,	bool,		s_atmosphere_fog_enable,				k_atmosphere_fog_enable)
CBUFFER_END

SHADER_CONST_ALIAS(EngineViewPS,	float3,		ps_camera_right,		ps_camera_to_world_matrix._m00_m10_m20,		_ps_camera_right,		_ps_view_camera_to_world_matrix, 0)
SHADER_CONST_ALIAS(EngineViewPS,	float3,		ps_camera_up,			ps_camera_to_world_matrix._m01_m11_m21,		_ps_camera_up,			_ps_view_camera_to_world_matrix, 16)
SHADER_CONST_ALIAS(EngineViewPS,	float3,		ps_camera_backward,		ps_camera_to_world_matrix._m02_m12_m22,		_ps_camera_backward,	_ps_view_camera_to_world_matrix, 32)
SHADER_CONST_ALIAS(EngineViewPS,	float3,		ps_camera_position,		ps_camera_to_world_matrix._m03_m13_m23,		_ps_camera_position,	_ps_view_camera_to_world_matrix, 48)

PIXEL_TEXTURE_AND_SAMPLER(_2D,		ps_cloud_texture,				_ps_cloud_texture,						11)
PIXEL_TEXTURE_AND_SAMPLER(_2D,		ps_shadow_depth_map,			_ps_shadow_depth_map,					12)
PIXEL_SAMPLER(ps_bsp_point_sampler,		_ps_bsp_point_sampler,		13)
PIXEL_SAMPLER(ps_bsp_bilinear_sampler,	_ps_bsp_bilinear_sampler,	14)
PIXEL_TEXTURE_AND_SAMPLER(_2D,		ps_dynamic_light_texture,		_ps_view_dynamic_light_texture,			15)
PIXEL_TEXTURE_AND_SAMPLER(_CUBE,		ps_dynamic_light_texture_cube,	_ps_view_dynamic_light_texture_cube,	15)

PIXEL_TEXTURE(_2D,	ps_view_albedo,			_ps_view_albedo,		22)
PIXEL_TEXTURE(_2D,	ps_view_normal,			_ps_view_normal,		23)
PIXEL_TEXTURE(_2D,	ps_view_shadow_mask,	_ps_view_shadow_mask,	24)
PIXEL_TEXTURE_USING_SAMPLER(_2D_ARRAY,	ps_bsp_lightprobe_dir_and_bandwidth,		_ps_bsp_lightprobe_dir_and_bandwidth,		25,		ps_bsp_bilinear_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D_ARRAY,	ps_bsp_lightprobe_hdr_color,				_ps_bsp_lightprobe_hdr_color,				26,		ps_bsp_bilinear_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D,		ps_lightmap_sharpen_falloff,				_ps_lightmap_sharpen_falloff,				27,		ps_bsp_bilinear_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D,		ps_bsp_lightprobe_analytic,					_ps_bsp_lightprobe_analytic,				28,		ps_bsp_bilinear_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D,		ps_bsp_lightprobe_hybrid_overlay_macro,		_ps_bsp_lightprobe_hybrid_overlay_macro,	29,		ps_bsp_point_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D,		ps_bsp_lightprobe_hybrid_overlay_micro,		_ps_bsp_lightprobe_hybrid_overlay_micro,	30,		ps_bsp_point_sampler)
PIXEL_TEXTURE_USING_SAMPLER(_2D,		ps_bsp_lightprobe_hybrid_refinement,		_ps_bsp_lightprobe_hybrid_refinement,		31,		ps_bsp_bilinear_sampler)

//

VERTEX_TEXTURE_AND_SAMPLER(_2D,	vs_sampler_cloud, 			_vs_cloud_texture,				3)
VERTEX_TEXTURE_AND_SAMPLER(_2D,	vs_atmosphere_fog_table,	k_vs_atmosphere_fog_table,		2)

CBUFFER_BEGIN(EngineBSPPS)
	CBUFFER_CONST(EngineBSPPS,				float4,		ps_bsp_lightmap_compress_constant_1,	_ps_bsp_lightmap_compress_constant_1)
	CBUFFER_CONST(EngineBSPPS,				float4,		ps_bsp_lightmap_compress_constant_2,	_ps_bsp_lightmap_compress_constant_2)
	CBUFFER_CONST(EngineBSPPS,				float4,		ps_bsp_lightmap_scale_constants,		_ps_bsp_lightmap_scale_constants)
CBUFFER_END

CBUFFER_BEGIN(EngineBSPBoolPS)
	CBUFFER_CONST(EngineBSPBoolPS,			bool,		ps_boolean_using_floating_sun,				k_ps_boolean_using_floating_sun)
	CBUFFER_CONST(EngineBSPBoolPS,			bool,		ps_boolean_using_analytic_light,			k_ps_boolean_using_analytic_light)
	CBUFFER_CONST(EngineBSPBoolPS,			bool,		ps_boolean_using_analytic_light_gobo,		k_ps_boolean_using_analytic_light_gobo)
	CBUFFER_CONST(EngineBSPBoolPS,			bool,		ps_boolean_using_static_lightmap_only,		k_ps_boolean_using_static_lightmap_only)
	CBUFFER_CONST(EngineBSPBoolPS,			bool,		ps_bsp_boolean_enable_sharpened_falloff,	k_ps_bsp_boolean_enable_sharpened_falloff)
CBUFFER_END

CBUFFER_BEGIN(EngineModelPS)
	CBUFFER_CONST_ARRAY(EngineModelPS,		float4,		ps_dynamic_lights, [5],					_ps_simple_light_start)
	CBUFFER_CONST(EngineModelPS,				float4x3,	ps_dynamic_light_gobo_rotation,			_ps_dynamic_light_gobo_rotation)
	CBUFFER_CONST(EngineModelPS,				float4,		ps_material_blend_constant,				_ps_material_blend_constant)
	CBUFFER_CONST(EngineModelPS,				float4x3,	ps_light_rotation,						_ps_model_light_rotation)
	CBUFFER_CONST(EngineModelPS,				float4,		ps_cloud_constant,						_ps_cloud_constant)
	CBUFFER_CONST(EngineModelPS,				bool,		ps_dynamic_light_shadowing,					k_ps_bool_dynamic_light_shadowing)
	CBUFFER_CONST(EngineModelPS,				bool,		ps_dynamic_light_physically_correct,		k_ps_bool_dynamic_light_physically_correct)
	CBUFFER_CONST(EngineModelPS,				bool,		ps_dynamic_light_gobo,						k_ps_bool_dynamic_light_gobo)
CBUFFER_END

CBUFFER_BEGIN(EngineModelLightingPS)
	CBUFFER_CONST_ARRAY(EngineModelLightingPS,		float4,		ps_model_sh_lighting, [8],				_ps_model_sh_lighting)
	CBUFFER_CONST_ARRAY(EngineModelLightingPS,		float4,		ps_lighting_constants, [4],				_ps_lighting_constants)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_floating_shadow_light_direction,		_ps_floating_shadow_light_direction)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_floating_shadow_light_intensity,		_ps_floating_shadow_light_intensity)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_static_floating_shadow_sharpening,	_ps_floating_static_shadow_sharpening)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_analytic_light_position,				_ps_analytic_light_position)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_analytic_light_intensity,			_ps_analytic_light_intensity)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_analytic_light_gobo_rotation_matrix_0,	_ps_analytic_light_gobo_rotation_matrix_0)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_analytic_light_gobo_rotation_matrix_1,	_ps_analytic_light_gobo_rotation_matrix_1)
	CBUFFER_CONST(EngineModelLightingPS,				float4,		ps_analytic_light_gobo_rotation_matrix_2,	_ps_analytic_light_gobo_rotation_matrix_2)
CBUFFER_END

#define _VMF_VALUE { ps_lighting_constants[0], ps_lighting_constants[1], ps_lighting_constants[2], ps_lighting_constants[3] }
SHADER_CONST_ALIAS(EngineModelLightingPS,	float4,		ps_model_vmf_lighting[4], _VMF_VALUE,	_ps_model_vmf_lighting, 	_ps_lighting_constants,0)

CBUFFER_BEGIN(EngineForgeLightmapPS)
	CBUFFER_CONST(EngineForgeLightmapPS,		float4,		ps_forge_lightmap_packing_constant,		_ps_forge_lightmap_packing_constant)
	CBUFFER_CONST(EngineForgeLightmapPS,		float4,		ps_forge_lightmap_compress_constant,	_ps_forge_lightmap_compress_constant)
CBUFFER_END
	
CBUFFER_BEGIN(EngineMaterialPS)
	CBUFFER_CONST_ARRAY(EngineMaterialPS,		float4,		ps_material_object_parameters, [4],		eMPSR_firstMaterialPSEngineRegister)
	CBUFFER_CONST_ARRAY(EngineMaterialPS,		float4,		ps_material_generic_parameters, [4],	eMPSR_firstMaterialPSGenericRegister)
	CBUFFER_CONST(EngineMaterialPS,				float4,		ps_textureSize,							k_ps_texture_size)
CBUFFER_END

CBUFFER_BEGIN_FIXED(EngineMaterialTransformPS, 11)
	CBUFFER_CONST_ARRAY(EngineMaterialTransformPS,		float4,		ps_material_shader_transforms, [12],	eMPSR_firstMaterialPSTransformRegister)
CBUFFER_END

#endif

#endif 	// !defined(__ENGINE_DECLARE_PARAMETERS_FXH)