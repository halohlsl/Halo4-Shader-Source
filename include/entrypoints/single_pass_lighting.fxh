#if !defined(__ENTRYPOINTS_SINGLE_PASS_LIGHTING_FXH)
#define __ENTRYPOINTS_SINGLE_PASS_LIGHTING_FXH

#include "entrypoints/common.fxh"
#include "entrypoints/static_lighting.fxh"
#include "atmosphere/atmosphere.fxh"

////////////////////////////////////////////////////////////////////////////////
/// Basic single_pass lighting pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

// Utility function to calculate and output the atmospheric scattering parameters
#define CALC_ATMOSPHERIC_SCATTERING(input, outputAtmospherics)					\
	ComputeAtmosphericScattering(												\
		vs_atmosphere_fog_table,												\
		input.position.xyz - vs_view_camera_position,							\
		input.position.xyz,														\
		outputAtmospherics.inscatter.rgb,										\
		outputAtmospherics.extinction.x,										\
		outputAtmospherics.extinction.y,										\
		false,																	\
		false);																	\
	outputAtmospherics.inscatter.rgb *= vs_material_blend_constant.y;

#if defined(xenon) || (DX_VERSION == 11)

#define BUILD_SINGLE_PASS_VS(vertex_type)										\
void single_pass_default_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_shader_output_atmosphere outputAtmospherics)							\
{																				\
	BUILD_BASE_VS(vertex_type);													\
	output.shadowProjection = 0;												\
	CALC_ATMOSPHERIC_SCATTERING(input, outputAtmospherics);						\
}

#else

#define BUILD_SINGLE_PASS_VS(vertex_type)										\
void single_pass_default_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_shader_output_atmosphere outputAtmospherics)							\
{																				\
	BUILD_BASE_VS(vertex_type);													\
	CALC_ATMOSPHERIC_SCATTERING(input, outputAtmospherics);						\
}

#endif

// Build vertex shaders for the single_pass lighting pass
BUILD_SINGLE_PASS_VS(world);								// single_pass_default_world_vs
BUILD_SINGLE_PASS_VS(rigid);								// single_pass_default_rigid_vs
BUILD_SINGLE_PASS_VS(skinned);								// single_pass_default_skinned_vs
BUILD_SINGLE_PASS_VS(rigid_boned);							// single_pass_default_rigid_boned_vs
BUILD_SINGLE_PASS_VS(rigid_blendshaped);					// single_pass_default_rigid_blendshaped_vs
BUILD_SINGLE_PASS_VS(skinned_blendshaped);					// single_pass_default_skinned_blendshaped_vs


///////////////////////////////////////////////////////////////////////////////
/// Per pixel lighting vertex shaders
///////////////////////////////////////////////////////////////////////////////

// Utility function to calculate and output the per-pixel lightmap coordinates
#define CALC_LIGHTING_TEXCOORD(input_lightmap, outputTexcoord)					\
	outputTexcoord = input_lightmap.texcoord;

#define BUILD_SINGLE_PASS_PER_PIXEL_VS(vertex_type)								\
void single_pass_per_pixel_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	in s_lightmap_per_pixel input_lightmap,										\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_shader_output_atmosphere outputAtmospherics)							\
{																				\
	single_pass_default_##vertex_type##_vs(input, out_position, output, outputAtmospherics);\
	CALC_LIGHTING_TEXCOORD(input_lightmap, output.texcoord.zw);					\
}

// Generate vertex shaders for per-pixel lighting in the single_pass lighting pass
BUILD_SINGLE_PASS_PER_PIXEL_VS(world);						// single_pass_per_pixel_world_vs
BUILD_SINGLE_PASS_PER_PIXEL_VS(rigid);						// single_pass_per_pixel_rigid_vs
BUILD_SINGLE_PASS_PER_PIXEL_VS(skinned);					// single_pass_per_pixel_skinned_vs
BUILD_SINGLE_PASS_PER_PIXEL_VS(rigid_boned);				// single_pass_per_pixel_rigid_boned_vs
BUILD_SINGLE_PASS_PER_PIXEL_VS(rigid_blendshaped);			// single_pass_per_pixel_rigid_blendshaped_vs
BUILD_SINGLE_PASS_PER_PIXEL_VS(skinned_blendshaped);		// single_pass_per_pixel_skinned_blendshaped_vs


///////////////////////////////////////////////////////////////////////////////
/// Per vertex lighting vertex shaders

#if defined(xenon) || (DX_VERSION == 11)
#define BUILD_SINGLE_PASS_PER_VERTEX_VS(vertex_type)							\
void single_pass_per_vertex_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	in uint vertexIndex : SV_VertexID,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,						\
	out s_shader_output_atmosphere outputAtmospherics)							\
{																				\
	single_pass_default_##vertex_type##_vs(input, out_position, output, outputAtmospherics);\
	sample_lightprobe_texture_565_vs(vertexIndex, vmf_sample_vertex);			\
}
#else	// defined(xenon)
// Only Xenon or D3D11 can do the per-vertex lighting using the vertex tfetches
#define BUILD_SINGLE_PASS_PER_VERTEX_VS(vertex_type)							\
void single_pass_per_vertex_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output,											\
	out s_shader_output_atmosphere outputAtmospherics)							\
{																				\
	single_pass_default_##vertex_type##_vs(input, out_position, output, outputAtmospherics);\
}
#endif	// defined(xenon)

// Generate vertex shaders for per-vertex lighting in the single_pass lighting pass
BUILD_SINGLE_PASS_PER_VERTEX_VS(world);						// single_pass_per_vertex_world_vs
BUILD_SINGLE_PASS_PER_VERTEX_VS(rigid);						// single_pass_per_vertex_rigid_vs
BUILD_SINGLE_PASS_PER_VERTEX_VS(skinned);					// single_pass_per_vertex_skinned_vs
BUILD_SINGLE_PASS_PER_VERTEX_VS(rigid_boned);				// single_pass_per_vertex_rigid_boned_vs
BUILD_SINGLE_PASS_PER_VERTEX_VS(rigid_blendshaped);			// single_pass_per_vertex_rigid_blendshaped_vs
BUILD_SINGLE_PASS_PER_VERTEX_VS(skinned_blendshaped);		// single_pass_per_vertex_skinned_blendshaped_vs



///////////////////////////////////////////////////////////////////////////////
/// Probe lighting vertex shaders
///////////////////////////////////////////////////////////////////////////////

// Nothing unique from the basic single_pass lighting shaders
#define single_pass_sh_world_vs								single_pass_default_world_vs
#define single_pass_sh_rigid_vs								single_pass_default_rigid_vs
#define single_pass_sh_skinned_vs							single_pass_default_skinned_vs
#define single_pass_sh_rigid_boned_vs						single_pass_default_rigid_boned_vs
#define single_pass_sh_rigid_blendshaped_vs					single_pass_default_rigid_blendshaped_vs
#define single_pass_sh_skinned_blendshaped_vs				single_pass_default_skinned_blendshaped_vs

///////////////////////////////////////////////////////////////////////////////
/// Per vertex lighting vertex shaders (color?)
///////////////////////////////////////////////////////////////////////////////

// Nothing unique from the basic single_pass lighting shaders
#define single_pass_single_probe_world_vs					single_pass_default_world_vs
#define single_pass_single_probe_rigid_vs					single_pass_default_rigid_vs
#define single_pass_single_probe_skinned_vs					single_pass_default_skinned_vs
#define single_pass_single_probe_rigid_boned_vs				single_pass_default_rigid_boned_vs
#define single_pass_single_probe_rigid_blendshaped_vs		single_pass_default_rigid_blendshaped_vs
#define single_pass_single_probe_skinned_blendshaped_vs		single_pass_default_skinned_blendshaped_vs


///////////////////////////////////////////////////////////////////////////////
/// Shadowed, no fog vertex shaders (just use the static lighting versions)
///////////////////////////////////////////////////////////////////////////////
// per-pixel
#define single_pass_shadowed_no_fog_per_pixel_world_vs					static_per_pixel_world_vs
#define single_pass_shadowed_no_fog_per_pixel_rigid_vs					static_per_pixel_rigid_vs
#define single_pass_shadowed_no_fog_per_pixel_skinned_vs				static_per_pixel_skinned_vs
#define single_pass_shadowed_no_fog_per_pixel_rigid_boned_vs			static_per_pixel_rigid_boned_vs
#define single_pass_shadowed_no_fog_per_pixel_rigid_blendshaped_vs		static_per_pixel_rigid_blendshaped_vs
#define single_pass_shadowed_no_fog_per_pixel_skinned_blendshaped_vs	static_per_pixel_skinned_blendshaped_vs

// per-vertex
#define single_pass_shadowed_no_fog_per_vertex_world_vs					static_per_vertex_world_vs
#define single_pass_shadowed_no_fog_per_vertex_rigid_vs					static_per_vertex_rigid_vs
#define single_pass_shadowed_no_fog_per_vertex_skinned_vs				static_per_vertex_skinned_vs
#define single_pass_shadowed_no_fog_per_vertex_rigid_boned_vs			static_per_vertex_rigid_boned_vs
#define single_pass_shadowed_no_fog_per_vertex_rigid_blendshaped_vs		static_per_vertex_rigid_blendshaped_vs
#define single_pass_shadowed_no_fog_per_vertex_skinned_blendshaped_vs	static_per_vertex_skinned_blendshaped_vs

// single probe
#define single_pass_shadowed_no_fog_single_probe_world_vs					static_probe_world_vs
#define single_pass_shadowed_no_fog_single_probe_rigid_vs					static_probe_rigid_vs
#define single_pass_shadowed_no_fog_single_probe_skinned_vs					static_probe_skinned_vs
#define single_pass_shadowed_no_fog_single_probe_rigid_boned_vs				static_probe_rigid_boned_vs
#define single_pass_shadowed_no_fog_single_probe_rigid_blendshaped_vs		static_probe_rigid_blendshaped_vs
#define single_pass_shadowed_no_fog_single_probe_skinned_blendshaped_vs		static_probe_skinned_blendshaped_vs

///////////////////////////////////////////////////////////////////////////////
/// As decal
///////////////////////////////////////////////////////////////////////////////
#define single_pass_as_decal_world_vs					albedo_world_vs
#define single_pass_as_decal_rigid_vs					albedo_rigid_vs
#define single_pass_as_decal_skinned_vs					albedo_skinned_vs
#define single_pass_as_decal_rigid_boned_vs				albedo_rigid_boned_vs
#define single_pass_as_decal_rigid_blendshaped_vs		albedo_rigid_blendshaped_vs
#define single_pass_as_decal_skinned_blendshaped_vs		albedo_skinned_blendshaped_vs

s_shader_output_atmosphere get_default_input_atmospherics()
{
	s_shader_output_atmosphere outAtmosphere;
	outAtmosphere.inscatter = 0;
	outAtmosphere.extinction= 0;

	return outAtmosphere;
}

float4 CommonSinglePassLightingPostPS(
	in s_pixel_shader_input pixel_shader_input,
	in s_shader_data shader_data,
	in s_shader_output_atmosphere inputAtmospherics,
	in s_platform_pixel_input platformInput,
	uniform bool useFog,
	uniform int lightingMode)
{
	// add the analytic light to the light list
	bool useFloatingShadow = ps_boolean_using_floating_sun;
	bool useAnalyticLight = ps_boolean_using_analytic_light;

	// Apply shadows to the lighting data
	if (!useFog)
	{
		generate_shadow_mask(shader_data.common, platformInput, ps_view_shadow_mask);
		apply_shadow_mask_to_vmf(shader_data.common, useFloatingShadow, lightingMode);
	}

	add_analytic_light_to_light_data(
		shader_data.common,
		shader_data.common.lighting_data.vmf_data,
		useFloatingShadow,
		useAnalyticLight);

	// Run the user shader to get the lit pixel value
	float4 litPixel = pixel_lighting(pixel_shader_input, shader_data);
	if (useFog)
	{
		litPixel = ApplyAtmosphericScattering(litPixel, inputAtmospherics.inscatter, inputAtmospherics.extinction.x);
	}
	litPixel = ApplyExposureSelfIllum(litPixel, shader_data.common.selfIllumIntensity, true);		// assume single pass is alpha blended
	
#if DX_VERSION == 11
	return max(0, litPixel);
#else
	return litPixel;
#endif
}

float4 CommonPerPixelSinglePassLightingPS(
	in s_pixel_shader_input pixel_shader_input,
	in s_shader_output_atmosphere inputAtmospherics,
	in s_platform_pixel_input platformInput,
	uniform bool useFog)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, platformInput, LM_PER_PIXEL);
	shader_data.common.shaderPass = SP_SINGLE_PASS_LIGHTING;

	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	// sample the lightprobe texture
	sample_lightprobe_texture(
		pixel_shader_input.texcoord.zw,
		shader_data.common.view_dir_distance.w,
		shader_data.common,
		shader_data.common.lighting_data.vmf_data,
		LM_PER_PIXEL);

	return CommonSinglePassLightingPostPS(pixel_shader_input, shader_data, inputAtmospherics, platformInput, useFog, LM_PER_PIXEL);
}

float4 CommonVMFSinglePassLightingPS(
	in s_pixel_shader_input pixel_shader_input,
	in s_shader_output_atmosphere inputAtmospherics,
	in s_platform_pixel_input platformInput,
	in s_vmf_sample_data vmfSample,
	uniform bool useFog,
	uniform int lightingMode)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, platformInput, lightingMode);
	shader_data.common.shaderPass = SP_SINGLE_PASS_LIGHTING;

	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	// Set the lighting sample
	shader_data.common.lighting_data.vmf_data = vmfSample;

	return CommonSinglePassLightingPostPS(pixel_shader_input, shader_data, inputAtmospherics, platformInput, useFog, lightingMode);
}

void single_pass_per_pixel_default_ps(
	in s_pixel_shader_input pixel_shader_input,
	in s_platform_pixel_input platformInput,
	in s_shader_output_atmosphere inputAtmospherics,
	out float4 out_color: SV_Target0)
{
	out_color = CommonPerPixelSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, true);
}

void single_pass_per_vertex_default_ps(
	in s_pixel_shader_input pixel_shader_input,
	in s_platform_pixel_input platformInput,
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
	in s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,
#endif
	in s_shader_output_atmosphere inputAtmospherics,
	out float4 out_color: SV_Target0)
{
#if (!defined(xenon) && (DX_VERSION != 11)) || defined(DISABLE_VMF)
	s_vmf_sample_data vmf_sample_vertex = get_default_vmf_data();
#endif

	out_color = CommonVMFSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, vmf_sample_vertex, true, LM_DEFAULT);
}

void single_pass_single_probe_default_ps(
	in s_pixel_shader_input pixel_shader_input,
	in s_platform_pixel_input platformInput,
	in s_shader_output_atmosphere inputAtmospherics,
	out float4 out_color: SV_Target0)
{
	// get the lightprobe constants
	s_vmf_sample_data vmf_sample_vertex;
	sample_lightprobe_constants(vmf_sample_vertex);

	out_color = CommonVMFSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, vmf_sample_vertex, true, LM_PROBE);
}

void single_pass_shadowed_no_fog_per_pixel_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_color: SV_Target0)
{
	// Unpack the packed lighting shader inputs to the standard shader inputs
	s_pixel_shader_input pixel_shader_input = UnpackLightingShaderInput(packedInput);

	// don't actually need this
	s_shader_output_atmosphere inputAtmospherics = get_default_input_atmospherics();
	out_color = CommonPerPixelSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, false);
}

void single_pass_shadowed_no_fog_per_vertex_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
#if defined(xenon) || (DX_VERSION == 11)
	in s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,
#endif
	out float4 out_color: SV_Target0)
{
#if (!defined(xenon) && (DX_VERSION != 11))
	s_vmf_sample_data vmf_sample_vertex = get_default_vmf_data();
#endif

	// Unpack the packed lighting shader inputs to the standard shader inputs
	s_pixel_shader_input pixel_shader_input = UnpackLightingShaderInput(packedInput);

	// don't actually need this
	s_shader_output_atmosphere inputAtmospherics = get_default_input_atmospherics();

	out_color = CommonVMFSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, vmf_sample_vertex, false, LM_DEFAULT);
}

void single_pass_shadowed_no_fog_single_probe_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_color: SV_Target0)
{
	// get the lightprobe constants
	s_vmf_sample_data vmf_sample_vertex;
	sample_lightprobe_constants(vmf_sample_vertex);

	// Unpack the packed lighting shader inputs to the standard shader inputs
	s_pixel_shader_input pixel_shader_input = UnpackLightingShaderInput(packedInput);

	// don't actually need this
	s_shader_output_atmosphere inputAtmospherics = get_default_input_atmospherics();

	out_color = CommonVMFSinglePassLightingPS(pixel_shader_input, inputAtmospherics, platformInput, vmf_sample_vertex, false, LM_PROBE);
}

void single_pass_as_decal_default_ps(
	in s_pixel_shader_input pixel_shader_input,
	out float4 out_color: SV_Target0,
	out float4 out_normal: SV_Target1)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	shader_data.common.shaderPass = SP_SINGLE_PASS_LIGHTING;

	pixel_pre_lighting(pixel_shader_input, shader_data);

#if defined(pc) && (DX_VERSION != 11)
	apply_basic_albedo_lighting(pixel_shader_input, shader_data);
#endif

	out_color.rgb = shader_data.common.albedo;
	out_color.a = 0; // don't want to replace the user data

	out_normal.xy = EncodeWorldspaceNormal(shader_data.common.normal);
	out_normal.zw = 0; // don't want to replace the user data

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	float4 litPixel= pixel_lighting(pixel_shader_input, shader_data);
	litPixel *= ps_view_exposure.zzzw;
	out_color.a = litPixel.a;
	out_normal.a = litPixel.a; // do alpha blending with the normal value, too
}

#endif 	// !defined(__ENTRYPOINTS_STATIC_LIGHTING_FXH)