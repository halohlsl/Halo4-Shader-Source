#if !defined(__ENTRYPOINTS_STATIC_LIGHTING_FXH)
#define __ENTRYPOINTS_STATIC_LIGHTING_FXH

#include "entrypoints/common.fxh"
#include "entrypoints/albedo.fxh"

float4 fetch_albedo(
	in s_shader_data shader_data,
	in s_platform_pixel_input platformInput)
{
#if defined(xenon)
	float4 albedo;
	float2 screen_texcoord= platformInput.fragment_position.xy;
	asm
	{
		tfetch2D albedo, screen_texcoord, ps_view_albedo, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD = false
	};
	return albedo;
#elif DX_VERSION == 11
	float4 albedo;
	int3 screen_texcoord = int3(platformInput.fragment_position.xy, 0);
	albedo = ps_view_albedo.Load(screen_texcoord);
	return albedo;
#else
	return 0.5;
#endif
}

float4 fetch_normal(
	in s_shader_data shader_data,
	in s_platform_pixel_input platformInput)
{
#if defined(xenon)
	float4 normal;
	float2 screen_texcoord= platformInput.fragment_position.xy;
	asm
	{
		tfetch2D normal, screen_texcoord, ps_view_normal, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD = false
	};	
	normal.b = bx2_inv(normal.b);
	return normal;
#elif DX_VERSION == 11
	float4 normal;
	int3 screen_texcoord = int3(platformInput.fragment_position.xy, 0);
	normal = ps_view_normal.Load(screen_texcoord);
	return normal;
#else
	return float4(0, 0, 0, 0);
#endif
}

void SampleDeferredBuffers(
	inout s_shader_data shader_data,
	in s_platform_pixel_input platformInput)
{
	// Copy over the platform input
	shader_data.common.platform_input = platformInput;

	// Sample the albedo buffer
	float4 albedo = fetch_albedo(shader_data, platformInput);
	shader_data.common.albedo.rgb = albedo.rgb;
	shader_data.common.albedo.a = 1.0f;

	// Sample and decode the normal buffer
	float4 normal = fetch_normal(shader_data, platformInput);
#ifdef xenon	
	shader_data.common.normal = DecodeWorldspaceNormalSigned(normal.xy);
#else
	shader_data.common.normal = DecodeWorldspaceNormal(normal.xy);
#endif

	// Fill in the shader values that are stored in the deferred buffer
	shader_data.common.shaderValues.x = normal.b;	// 10 bits
	shader_data.common.shaderValues.y = albedo.a;	// 8 bits
	shader_data.common.shaderValues.z = normal.a;	// 2 bits
}

float4 CommonPerPixelLightingPS(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	uniform int lightingMode)
{
	// Unpack the packed lighting shader inputs to the standard shader inputs
	s_pixel_shader_input pixel_shader_input = UnpackLightingShaderInput(packedInput);

	// Set up the shader data structure from the shader input
	s_shader_data shader_data = init_shader_data(pixel_shader_input, platformInput, lightingMode);
	shader_data.common.shaderPass = SP_STATIC_LIGHTING;

	// Run the 'pre-lighting' phase to ensure that nothing is missed from the albedo shader
	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Read and decode data from the deferred buffers (hopefully replacing most of the 'pre-lighting' output)
	SampleDeferredBuffers(shader_data, platformInput);

	// Sample the lighting
	if (lightingMode == LM_PER_PIXEL_FORGE)
	{
		// forge sampling function is special, since we treat the lightmaps differently
		sample_lightprobe_texture_forge(
			pixel_shader_input.texcoord.zw,
			shader_data.common.view_dir_distance.w,
			shader_data.common,
			shader_data.common.geometricNormal,
			shader_data.common.lighting_data.vmf_data);
	}
	else if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE || lightingMode == LM_PER_PIXEL_SIMPLE)
	{
		// Simpified irradiance lighting
		sample_lightprobe_texture_simple_irradiance(
			pixel_shader_input.texcoord.zw,
			shader_data.common.view_dir_distance.w,
			shader_data.common,
			shader_data.common.lighting_data.vmf_data,
			lightingMode);
	}
	else if (lightingMode == LM_PROBE_AO)
	{
		// Simpified irradiance lighting
		sample_lightprobe_texture_ao(
			pixel_shader_input.texcoord.zw,
			shader_data.common.view_dir_distance.w,
			shader_data.common,
			shader_data.common.lighting_data.vmf_data,
			lightingMode);
	}
	else
	{
		sample_lightprobe_texture(
			pixel_shader_input.texcoord.zw,
			shader_data.common.view_dir_distance.w,
			shader_data.common,
			shader_data.common.lighting_data.vmf_data,
			lightingMode);
	}

	// Some lighting modes apply a visibility term
	if (lightingMode == LM_OBJECT || lightingMode == LM_PROBE_AO)
	{
		shader_data.common.lighting_data.visibility = VMFGetAnalyticLightScalar(shader_data.common.lighting_data.vmf_data);
		VMFSetAnalyticLightScalarFromAirprobe(shader_data.common.lighting_data.vmf_data);
	}
	
	if (lightingMode == LM_PROBE_AO)
	{
		VMFScaleValues(shader_data.common.lighting_data.vmf_data, shader_data.common.lighting_data.visibility);
	}	

	// Determine what kind of analytic lights need to be added
	bool useFloatingShadow, useAnalyticLight;
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW || lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE)
	{
		useFloatingShadow = true;
		useAnalyticLight = false;
	}
	else if (lightingMode == LM_PER_PIXEL_ANALYTIC || lightingMode == LM_PER_PIXEL_ANALYTIC_HR)
	{
		useFloatingShadow = false;
		useAnalyticLight = true;
	}
	else if (lightingMode == LM_PER_PIXEL || lightingMode == LM_PER_PIXEL_HR || lightingMode == LM_PER_PIXEL_SIMPLE)
	{
		useFloatingShadow = false;
		useAnalyticLight = false;
	}
	else if (lightingMode == LM_OBJECT)
	{
		useFloatingShadow = ps_boolean_using_floating_sun;
		useAnalyticLight = false;
	}
	else
	{
		useFloatingShadow = ps_boolean_using_floating_sun;
		useAnalyticLight = ps_boolean_using_analytic_light;
	}

	// Apply shadows to the lighting data
	generate_shadow_mask(shader_data.common, platformInput, ps_view_shadow_mask);
	apply_shadow_mask_to_vmf(shader_data.common, useFloatingShadow, lightingMode);

	// Add the analytic light to the light list
	add_analytic_light_to_light_data(
		shader_data.common,
		shader_data.common.lighting_data.vmf_data,
		useFloatingShadow,
		useAnalyticLight);

	// Run the user shader to get the lit pixel value
	float4 litPixel = pixel_lighting(pixel_shader_input, shader_data);

	// Apply exposure and output
	litPixel = ApplyExposureSelfIllum(litPixel, shader_data.common.selfIllumIntensity);
	litPixel.a = shader_data.common.selfIllumIntensity;

#if DX_VERSION == 11
	return max(litPixel, 0);
#else
	return litPixel;
#endif	
}


float4 CommonPerVertexLightingPS(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	in s_vmf_sample_data vmfSample,
	in float visibilityTerm,
	uniform int lightingMode)
{
	// Unpack the packed lighting shader inputs to the standard shader inputs
	s_pixel_shader_input pixel_shader_input = UnpackLightingShaderInput(packedInput);

	// Set up the shader data structure from the shader input
	s_shader_data shader_data = init_shader_data(pixel_shader_input, platformInput, lightingMode);
	shader_data.common.shaderPass = SP_STATIC_LIGHTING;

	// Run the 'pre-lighting' phase to ensure that nothing is missed from the albedo shader
	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Read and decode data from the deferred buffers (hopefully replacing most of the 'pre-lighting' output)
	SampleDeferredBuffers(shader_data, platformInput);

	// Set the lighting sample
	shader_data.common.lighting_data.vmf_data = vmfSample;

	// Some lighting modes apply a visibility term
	if (lightingMode == LM_OBJECT)
	{
		shader_data.common.lighting_data.visibility = VMFGetAnalyticLightScalar(shader_data.common.lighting_data.vmf_data);
		VMFSetAnalyticLightScalarFromAirprobe(shader_data.common.lighting_data.vmf_data);
	}
	
	if (lightingMode == LM_PROBE_AO)
	{
		shader_data.common.lighting_data.visibility = visibilityTerm;
	}

	// Apply shadows to the lighting data
	generate_shadow_mask(shader_data.common, platformInput, ps_view_shadow_mask);
	apply_shadow_mask_to_vmf(shader_data.common, ps_boolean_using_floating_sun, lightingMode);

	// Add the analytic light to the light list
	bool useFloatingShadow = ps_boolean_using_floating_sun;
	bool useAnalyticLight;
	
	if (lightingMode == LM_OBJECT)
	{
		useAnalyticLight = false;
	}
	else
	{
		useAnalyticLight = ps_boolean_using_analytic_light;
	}
	
	add_analytic_light_to_light_data(
		shader_data.common,
		shader_data.common.lighting_data.vmf_data,
		useFloatingShadow,
		useAnalyticLight);
		
	// Run the user shader to get the lit pixel value
	float4 litPixel = pixel_lighting(pixel_shader_input, shader_data);

	// Apply exposure and output
	litPixel = ApplyExposureSelfIllum(litPixel, shader_data.common.selfIllumIntensity);
	litPixel.a = shader_data.common.selfIllumIntensity;
	
#if DX_VERSION == 11
	return max(litPixel, 0);
#else
	return litPixel;
#endif	
}

void static_per_pixel_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL);
}

void static_per_pixel_hybrid_refinement_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_HR);
}

void static_per_pixel_analytic_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_ANALYTIC);
}

void static_per_pixel_analytic_hybrid_refinement_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_ANALYTIC_HR);
}

void static_per_pixel_floating_shadow_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_FLOATING_SHADOW);
}


void static_per_pixel_forge_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_FORGE);
}


void static_per_pixel_floating_shadow_simple_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE);
}


void static_per_pixel_simple_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PER_PIXEL_SIMPLE);
}


void static_per_pixel_object_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_OBJECT);
}

void static_per_pixel_ao_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	out_lighting = CommonPerPixelLightingPS(packedInput, platformInput, LM_PROBE_AO);
}


void static_per_vertex_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
	in s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,
#endif
	out float4 out_lighting: SV_Target0)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)
	s_vmf_sample_data vmf_sample_vertex = get_default_vmf_data();
#endif

	out_lighting = CommonPerVertexLightingPS(packedInput, platformInput, vmf_sample_vertex, 1.0f, LM_DEFAULT);
}

void static_per_vertex_ao_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
#if (defined(xenon) || (DX_VERSION==11))
	in s_vmf_ao_sample_data vmf_ao_sample_vertex : TEXCOORD6,
#endif
	out float4 out_lighting: SV_Target0)
{
	float visibilityTerm = 1.0f;

#if defined(xenon) || (DX_VERSION == 11)
	// get the lightprobe constants
	s_vmf_sample_data vmf_sample_vertex;
	sample_lightprobe_constants(vmf_sample_vertex);
	
	get_lightprobe_constants_from_ao(vmf_sample_vertex, vmf_ao_sample_vertex, visibilityTerm);
	
	// Scale VMF by visibility
	VMFScaleValues(vmf_sample_vertex, visibilityTerm);	
#else
	s_vmf_sample_data vmf_sample_vertex = get_default_vmf_data();
#endif
	
	out_lighting = CommonPerVertexLightingPS(packedInput, platformInput, vmf_sample_vertex, visibilityTerm, LM_PROBE_AO);
}


void static_per_vertex_object_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
	in s_vmf_sample_data vmf_sample_vertex : TEXCOORD6,
#endif
	out float4 out_lighting: SV_Target0)
{
#if (!defined(xenon) && (DX_VERSION == 9))|| defined(DISABLE_VMF)
	s_vmf_sample_data vmf_sample_vertex = get_default_vmf_data();
#endif

	out_lighting = CommonPerVertexLightingPS(packedInput, platformInput, vmf_sample_vertex, 1.0f, LM_OBJECT);
}


void static_probe_default_ps(
	in s_lighting_pixel_shader_input packedInput,
	in s_platform_pixel_input platformInput,
	out float4 out_lighting: SV_Target0)
{
	// get the lightprobe constants
	s_vmf_sample_data vmf_sample_vertex;
	sample_lightprobe_constants(vmf_sample_vertex);

	out_lighting = CommonPerVertexLightingPS(packedInput, platformInput, vmf_sample_vertex, 1.0f, LM_PROBE);
}





////////////////////////////////////////////////////////////////////////////////
/// Basic static lighting pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#define BUILD_STATIC_VS(vertex_type)											\
void static_default_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_lighting_vertex_shader_output packed)									\
{																				\
	s_vertex_shader_output output;												\
	BUILD_BASE_VS(vertex_type);													\
	packed = PackLightingShaderOutput(output);									\
}

// Build vertex shaders for the static lighting pass
BUILD_STATIC_VS(world);										// static_default_world_vs
BUILD_STATIC_VS(rigid);										// static_default_rigid_vs
BUILD_STATIC_VS(skinned);									// static_default_skinned_vs
BUILD_STATIC_VS(rigid_boned);								// static_default_rigid_boned_vs
BUILD_STATIC_VS(rigid_blendshaped);							// static_default_rigid_blendshaped_vs
BUILD_STATIC_VS(skinned_blendshaped);						// static_default_skinned_blendshaped_vs


///////////////////////////////////////////////////////////////////////////////
/// Per pixel lighting vertex shaders
///////////////////////////////////////////////////////////////////////////////

// Utility function to calculate and output the per-pixel lightmap coordinates
#define CALC_LIGHTING_TEXCOORD(input_lightmap, outputTexcoord)					\
	outputTexcoord = input_lightmap.texcoord;

#define BUILD_STATIC_PER_PIXEL_VS(vertex_type)									\
void static_per_pixel_##vertex_type##_vs(										\
	in s_##vertex_type##_vertex input,											\
	in s_lightmap_per_pixel input_lightmap,										\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_lighting_vertex_shader_output output)									\
{																				\
	static_default_##vertex_type##_vs(input, out_position, output);				\
	CALC_LIGHTING_TEXCOORD(input_lightmap, output.texcoord.zw);					\
}

// Generate vertex shaders for per-pixel lighting in the static lighting pass
BUILD_STATIC_PER_PIXEL_VS(world);							// static_per_pixel_world_vs
BUILD_STATIC_PER_PIXEL_VS(rigid);							// static_per_pixel_rigid_vs
BUILD_STATIC_PER_PIXEL_VS(skinned);							// static_per_pixel_skinned_vs
BUILD_STATIC_PER_PIXEL_VS(rigid_boned);						// static_per_pixel_rigid_boned_vs
BUILD_STATIC_PER_PIXEL_VS(rigid_blendshaped);				// static_per_pixel_rigid_blendshaped_vs
BUILD_STATIC_PER_PIXEL_VS(skinned_blendshaped);				// static_per_pixel_skinned_blendshaped_vs


///////////////////////////////////////////////////////////////////////////////
/// Per vertex lighting vertex shaders

//  For our two per-vertex lighting types
#define per_vertex_func 			sample_lightprobe_texture_565_vs
#define per_vertex_ao_func 			sample_lightprobe_texture_565_ao_vs
#define per_vertex_type 			s_vmf_sample_data
#define per_vertex_ao_type 			s_vmf_ao_sample_data

#if defined(xenon) || (DX_VERSION == 11)
#define BUILD_STATIC_PER_VERTEX_VS(vertex_type, entry_point)								\
void static_##entry_point##_##vertex_type##_vs(												\
	in s_##vertex_type##_vertex input,														\
	in uint vertexIndex : SV_VertexID,														\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,									\
	out s_lighting_vertex_shader_output output,												\
	out entry_point##_type vmf_sample_vertex : TEXCOORD6)									\
{																							\
	static_default_##vertex_type##_vs(input, out_position, output);							\
	entry_point##_func(vertexIndex, vmf_sample_vertex);	\
}
#else	// defined(xenon)
// Only Xenon or D3D11 can do the per-vertex lighting using the vertex tfetches
#define BUILD_STATIC_PER_VERTEX_VS(vertex_type, entry_point)					\
void static_##entry_point##_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_lighting_vertex_shader_output output)									\
{																				\
	static_default_##vertex_type##_vs(input, out_position, output);\
}
#endif	// defined(xenon)

// Generate vertex shaders for per-vertex lighting in the static lighting pass
BUILD_STATIC_PER_VERTEX_VS(world, per_vertex);					// static_per_vertex_world_vs
BUILD_STATIC_PER_VERTEX_VS(rigid, per_vertex);					// static_per_vertex_rigid_vs
BUILD_STATIC_PER_VERTEX_VS(skinned, per_vertex);				// static_per_vertex_skinned_vs
BUILD_STATIC_PER_VERTEX_VS(rigid_boned, per_vertex);			// static_per_vertex_rigid_boned_vs
BUILD_STATIC_PER_VERTEX_VS(rigid_blendshaped, per_vertex);		// static_per_vertex_rigid_blendshaped_vs
BUILD_STATIC_PER_VERTEX_VS(skinned_blendshaped, per_vertex);	// static_per_vertex_skinned_blendshaped_vs

BUILD_STATIC_PER_VERTEX_VS(world, per_vertex_ao);					// static_per_vertex_ao_world_vs
BUILD_STATIC_PER_VERTEX_VS(rigid, per_vertex_ao);					// static_per_vertex_ao_rigid_vs
BUILD_STATIC_PER_VERTEX_VS(skinned, per_vertex_ao);					// static_per_vertex_ao_skinned_vs
BUILD_STATIC_PER_VERTEX_VS(rigid_boned, per_vertex_ao);				// static_per_vertex_ao_rigid_boned_vs
BUILD_STATIC_PER_VERTEX_VS(rigid_blendshaped, per_vertex_ao);		// static_per_vertex_ao_rigid_blendshaped_vs
BUILD_STATIC_PER_VERTEX_VS(skinned_blendshaped, per_vertex_ao);		// static_per_vertex_ao_skinned_blendshaped_vs

///////////////////////////////////////////////////////////////////////////////
/// Probe lighting vertex shaders
///////////////////////////////////////////////////////////////////////////////

// Nothing unique from the basic static lighting shaders
#define static_probe_world_vs								static_default_world_vs
#define static_probe_rigid_vs								static_default_rigid_vs
#define static_probe_skinned_vs								static_default_skinned_vs
#define static_probe_rigid_boned_vs							static_default_rigid_boned_vs
#define static_probe_rigid_blendshaped_vs					static_default_rigid_blendshaped_vs
#define static_probe_skinned_blendshaped_vs					static_default_skinned_blendshaped_vs

///////////////////////////////////////////////////////////////////////////////
/// Object vertex shaders
///////////////////////////////////////////////////////////////////////////////

// Also nothing unique from the basic static lighting shaders
#define static_per_pixel_hybrid_refinement_world_vs						static_per_pixel_world_vs
#define static_per_pixel_hybrid_refinement_rigid_vs						static_per_pixel_rigid_vs
#define static_per_pixel_hybrid_refinement_skinned_vs						static_per_pixel_skinned_vs
#define static_per_pixel_hybrid_refinement_rigid_boned_vs					static_per_pixel_rigid_boned_vs
#define static_per_pixel_hybrid_refinement_rigid_blendshaped_vs			static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_hybrid_refinement_skinned_blendshaped_vs			static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_analytic_world_vs					static_per_pixel_world_vs
#define static_per_pixel_analytic_rigid_vs					static_per_pixel_rigid_vs
#define static_per_pixel_analytic_skinned_vs				static_per_pixel_skinned_vs
#define static_per_pixel_analytic_rigid_boned_vs			static_per_pixel_rigid_boned_vs
#define static_per_pixel_analytic_rigid_blendshaped_vs		static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_analytic_skinned_blendshaped_vs	static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_analytic_hybrid_refinement_world_vs				static_per_pixel_world_vs
#define static_per_pixel_analytic_hybrid_refinement_rigid_vs				static_per_pixel_rigid_vs
#define static_per_pixel_analytic_hybrid_refinement_skinned_vs				static_per_pixel_skinned_vs
#define static_per_pixel_analytic_hybrid_refinement_rigid_boned_vs			static_per_pixel_rigid_boned_vs
#define static_per_pixel_analytic_hybrid_refinement_rigid_blendshaped_vs	static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_analytic_hybrid_refinement_skinned_blendshaped_vs	static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_floating_shadow_world_vs			static_per_pixel_world_vs
#define static_per_pixel_floating_shadow_rigid_vs			static_per_pixel_rigid_vs
#define static_per_pixel_floating_shadow_skinned_vs			static_per_pixel_skinned_vs
#define static_per_pixel_floating_shadow_rigid_boned_vs		static_per_pixel_rigid_boned_vs
#define static_per_pixel_floating_shadow_rigid_blendshaped_vs static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_floating_shadow_skinned_blendshaped_vs static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_ao_world_vs						static_per_pixel_world_vs
#define static_per_pixel_ao_rigid_vs						static_per_pixel_rigid_vs
#define static_per_pixel_ao_skinned_vs						static_per_pixel_skinned_vs
#define static_per_pixel_ao_rigid_boned_vs					static_per_pixel_rigid_boned_vs
#define static_per_pixel_ao_rigid_blendshaped_vs 			static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_ao_skinned_blendshaped_vs 			static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_floating_shadow_simple_world_vs			static_per_pixel_world_vs
#define static_per_pixel_floating_shadow_simple_rigid_vs			static_per_pixel_rigid_vs
#define static_per_pixel_floating_shadow_simple_skinned_vs			static_per_pixel_skinned_vs
#define static_per_pixel_floating_shadow_simple_rigid_boned_vs		static_per_pixel_rigid_boned_vs
#define static_per_pixel_floating_shadow_simple_rigid_blendshaped_vs static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_floating_shadow_simple_skinned_blendshaped_vs static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_simple_world_vs					static_per_pixel_world_vs
#define static_per_pixel_simple_rigid_vs					static_per_pixel_rigid_vs
#define static_per_pixel_simple_skinned_vs					static_per_pixel_skinned_vs
#define static_per_pixel_simple_rigid_boned_vs				static_per_pixel_rigid_boned_vs
#define static_per_pixel_simple_rigid_blendshaped_vs		static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_simple_skinned_blendshaped_vs		static_per_pixel_skinned_blendshaped_vs

#define static_per_pixel_object_world_vs					static_per_pixel_world_vs
#define static_per_pixel_object_rigid_vs					static_per_pixel_rigid_vs
#define static_per_pixel_object_skinned_vs					static_per_pixel_skinned_vs
#define static_per_pixel_object_rigid_boned_vs				static_per_pixel_rigid_boned_vs
#define static_per_pixel_object_rigid_blendshaped_vs		static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_object_skinned_blendshaped_vs		static_per_pixel_skinned_blendshaped_vs

#define static_per_vertex_object_world_vs					static_per_vertex_world_vs
#define static_per_vertex_object_rigid_vs					static_per_vertex_rigid_vs
#define static_per_vertex_object_skinned_vs					static_per_vertex_skinned_vs
#define static_per_vertex_object_rigid_boned_vs				static_per_vertex_rigid_boned_vs
#define static_per_vertex_object_rigid_blendshaped_vs		static_per_vertex_rigid_blendshaped_vs
#define static_per_vertex_object_skinned_blendshaped_vs		static_per_vertex_skinned_blendshaped_vs

#define static_per_pixel_forge_world_vs				static_per_pixel_world_vs
#define static_per_pixel_forge_rigid_vs				static_per_pixel_rigid_vs
#define static_per_pixel_forge_skinned_vs			static_per_pixel_skinned_vs
#define static_per_pixel_forge_rigid_boned_vs			static_per_pixel_rigid_boned_vs
#define static_per_pixel_forge_rigid_blendshaped_vs		static_per_pixel_rigid_blendshaped_vs
#define static_per_pixel_forge_skinned_blendshaped_vs		static_per_pixel_skinned_blendshaped_vs


#endif 	// !defined(__ENTRYPOINTS_STATIC_LIGHTING_FXH)