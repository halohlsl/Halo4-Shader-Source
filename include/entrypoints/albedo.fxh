#if !defined(__ENTRYPOINTS_ALBEDO_FXH)
#define __ENTRYPOINTS_ALBEDO_FXH

#include "entrypoints/common.fxh"

void apply_basic_albedo_lighting(
	in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	// calculate N.V to use as a falloff term for lighting
	float falloff = saturate(dot(shader_data.common.normal.xyz, -shader_data.common.view_dir_distance.xyz));

	// Use a base level of 'lighting'
	float basicLighting = lerp(0.1, 1.0, falloff);

	// scale albedo accordingly
	shader_data.common.albedo.rgb *= basicLighting;
}

void albedo_default_ps(
	in s_pixel_shader_input pixel_shader_input,
#if defined(FORCE_SINGLE_PASS) && (defined(xenon) || (DX_VERSION == 11))
	in s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,
#endif
	out float4 out_color: SV_Target0,
	out float4 out_normal: SV_Target1)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_ALBEDO);
	shader_data.common.shaderPass = SP_ALBEDO;

	pixel_pre_lighting(pixel_shader_input, shader_data);

#if defined(pc) && (DX_VERSION != 11)
	apply_basic_albedo_lighting(pixel_shader_input, shader_data);
#endif

	out_color.rgb = shader_data.common.albedo;
	out_color.a = shader_data.common.shaderValues.y;

	out_normal.xy = EncodeWorldspaceNormal(shader_data.common.normal);
	out_normal.zw = shader_data.common.shaderValues.xz;

#if defined(FORCE_SINGLE_PASS)
	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

#if defined(xenon) || (DX_VERSION == 11)
	// apply the vertex sample
	shader_data.common.lighting_data.vmf_data = vmf_sample_vertex;
#endif

	// add the analytic light to the light list
	bool useFloatingShadow = ps_boolean_using_floating_sun;
	bool useAnalyticLight = ps_boolean_using_analytic_light;
	add_analytic_light_to_light_data(
		shader_data.common,
		shader_data.common.lighting_data.vmf_data,
		useFloatingShadow,
		useAnalyticLight);

	out_color = pixel_lighting(pixel_shader_input, shader_data);
	out_color = PackRGBk(out_color);
#endif
}


////////////////////////////////////////////////////////////////////////////////
/// Base vertex shaders (called by most other vertex shaders)
////////////////////////////////////////////////////////////////////////////////

#if DX_VERSION == 11
#define BUILD_BASE_VS_CLIP output.clipDistance = dot(out_position, vs_clip_plane);
#define CLIP_OUTPUT out float clip_distance : SV_ClipDistance,
#define CLIP_INPUT in float clip_distance : SV_ClipDistance,
#define SET_CLIP_OUTPUT(_output) clip_distance = _output.clipDistance
#else
#define BUILD_BASE_VS_CLIP
#define CLIP_OUTPUT
#define CLIP_INPUT
#define SET_CLIP_OUTPUT(_output)
#endif

#define BUILD_BASE_VS(vertex_type)												\
	output= (s_vertex_shader_output)0;											\
	float4 local_to_world_transform[3];											\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);\
	output.texcoord= float4(input.texcoord.xy, input.texcoord1.xy);				\
	BUILD_BASE_VS_CLIP


////////////////////////////////////////////////////////////////////////////////
/// Albedo vertex shaders (called by most other vertex shaders)
////////////////////////////////////////////////////////////////////////////////

#if !defined(FORCE_SINGLE_PASS) || (!defined(xenon) && (DX_VERSION != 11))

// Build the basic albedo pass shaders
#define BUILD_ALBEDO_VS(vertex_type)											\
void albedo_##vertex_type##_vs(													\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output)											\
{																				\
	BUILD_BASE_VS(vertex_type);													\
}

#else

// Build the single-pass version of the albedo shaders
#define BUILD_ALBEDO_VS(vertex_type)											\
void albedo_##vertex_type##_vs(													\
	in s_##vertex_type##_vertex input,											\
	in uint vertexIndex : SV_VertexID,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_vmf_sample_data vmf_sample_vertex : TEXCOORD6)						\
{																				\
	BUILD_BASE_VS(vertex_type);													\
	sample_lightprobe_texture_565_vs(vertexIndex, vmf_sample_vertex);			\
	output.shadowProjection = 0;												\
}

#endif

// Build albedo vertex shaders
BUILD_ALBEDO_VS(world);										// albedo_world_vs
BUILD_ALBEDO_VS(rigid);										// albedo_rigid_vs
BUILD_ALBEDO_VS(skinned);									// albedo_skinned_vs
BUILD_ALBEDO_VS(rigid_boned);								// albedo_rigid_boned_vs
BUILD_ALBEDO_VS(rigid_blendshaped);							// albedo_rigid_blendshaped_vs
BUILD_ALBEDO_VS(skinned_blendshaped);						// albedo_skinned_blendshaped_vs


#endif 	// !defined(__ENTRYPOINTS_ALBEDO_FXH)