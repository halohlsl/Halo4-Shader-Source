#if !defined(__ENTRYPOINTS_DYNAMIC_LIGHTING_FXH)
#define __ENTRYPOINTS_DYNAMIC_LIGHTING_FXH

#include "entrypoints/common.fxh"
#include "entrypoints/static_lighting.fxh"
#include "dynamic_lighting_registers.fxh"


#define		LIGHT_DATA(offset, registers)	(ps_dynamic_lights[offset].registers)
#define		LIGHT_POSITION					LIGHT_DATA(0, xyz)
#define		LIGHT_DIRECTION					LIGHT_DATA(1, xyz)
#define		LIGHT_COLOR						LIGHT_DATA(2, xyz)
#define		LIGHT_SPECULAR_SCALAR			LIGHT_DATA(1, w)
#define		LIGHT_DIFFUSE_SCALAR			LIGHT_DATA(2, w)
#define		LIGHT_COSINE_CUTOFF_ANGLE 		LIGHT_DATA(3, x)
#define		LIGHT_ANGLE_FALLOFF_RAIO 		LIGHT_DATA(3, y)
#define		LIGHT_ANGLE_FALLOFF_POWER 		LIGHT_DATA(3, z)
#define		LIGHT_FAR_ATTENUATION_END 		LIGHT_DATA(4, y)
#define		LIGHT_FAR_ATTENUATION_RATIO 	LIGHT_DATA(4, z)
#define		LIGHT_BOUNDING_RADIUS			LIGHT_DATA(4, x)


static void add_spotlight_to_light_data(
	inout s_lighting_components lighting_data,
	in const float3 fragment_position_world,
	in const float4 fragment_position_shadow,
	in const float2 pixel_pos)
{
#if defined(xenon) || (DX_VERSION == 11)
	// calculate direction to light (4 instructions)
	float3 fragment_to_light_unnormalized= LIGHT_POSITION - fragment_position_world;			// vector from fragment to light
	float  light_dist2= dot(fragment_to_light_unnormalized, fragment_to_light_unnormalized);	// distance to the light, squared
	float distance= sqrt(light_dist2);
	float3 fragment_to_light = fragment_to_light_unnormalized / distance;						// normalized vector pointing to the light

	float2 falloff;
	
	// linear^3 is a closer approximation to distance^2 than linear^2
	falloff.x = saturate((LIGHT_FAR_ATTENUATION_END  - distance) * LIGHT_FAR_ATTENUATION_RATIO); // distance based falloff (2 instructions)
	falloff.x *= falloff.x * falloff.x;

	falloff.y= saturate( ( dot(fragment_to_light, LIGHT_DIRECTION) - LIGHT_COSINE_CUTOFF_ANGLE ) * LIGHT_ANGLE_FALLOFF_RAIO);
	falloff.y= pow(falloff.y, LIGHT_ANGLE_FALLOFF_POWER);

	float combined_falloff = falloff.x * falloff.y; // (1 instruction)

	float3 shadow_projection = fragment_position_shadow.xyz / fragment_position_shadow.w; // projective transform on xy coordinates

	float unshadowed_percentage = 1.0f;

	// apply shadow to falloff
	if (ps_dynamic_light_shadowing)
	{
		unshadowed_percentage = midgraph_poisson_shadow_8tap(shadow_projection, pixel_pos);
		combined_falloff *= unshadowed_percentage;
	}

	float3 light_radiance = LIGHT_COLOR * combined_falloff * VMF_BANDWIDTH;

	// apply gobo
	if (ps_dynamic_light_gobo)
	{
		float3 light_to_fragment_lightspace = mul(float4(-fragment_to_light_unnormalized, 1.0f), ps_dynamic_light_gobo_rotation);
		light_to_fragment_lightspace.xy /= light_to_fragment_lightspace.z;

		light_radiance *= sample2D(ps_dynamic_light_texture, light_to_fragment_lightspace.yx).rgb; 
	}

	lighting_data.light_direction_specular_scalar[lighting_data.light_component_count]= float4(fragment_to_light, LIGHT_SPECULAR_SCALAR);
	lighting_data.light_intensity_diffuse_scalar[lighting_data.light_component_count]= float4(light_radiance, LIGHT_DIFFUSE_SCALAR);
	++lighting_data.light_component_count;
#endif
}



void midnight_spotlight_default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos),
	in s_pixel_shader_input pixel_shader_input,
	in s_platform_pixel_input platformInput,
	out float4 out_color: SV_Target0)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, platformInput, LM_DYNAMIC_LIGHTING);
	shader_data.common.shaderPass = SP_DYNAMIC_LIGHTING;

	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Read and decode data from the deferred buffers
	SampleDeferredBuffers(shader_data, platformInput);

	// add the spot light to the light list
	add_spotlight_to_light_data(shader_data.common.lighting_data, shader_data.common.position, shader_data.common.shadowProjection, pixel_pos);

	out_color= pixel_lighting(pixel_shader_input, shader_data);
	out_color= apply_exposure(out_color);

	out_color.a = 0.0f;
}


#if defined(xenon) || (DX_VERSION == 11)
#define OUPUT_SHADOW_PROJECTION(position)										\
	output.shadowProjection = mul(float4(position.xyz, 1.f), vs_shadow_projection)
#else
#define OUPUT_SHADOW_PROJECTION(position)
#endif

////////////////////////////////////////////////////////////////////////////////
/// Basic dynamic lighting pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#define BUILD_DYNAMIC_SPOTLIGHT_VS(vertex_type)									\
void midnight_spotlight_##vertex_type##_vs(										\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,						\
	out s_vertex_shader_output output)											\
{																				\
	BUILD_BASE_VS(vertex_type);													\
	OUPUT_SHADOW_PROJECTION(input.position);									\
}

// Build vertex shaders for the dynamic spotlight pass
BUILD_DYNAMIC_SPOTLIGHT_VS(world);							// midnight_spotlight_world_vs
BUILD_DYNAMIC_SPOTLIGHT_VS(rigid);							// midnight_spotlight_rigid_vs
BUILD_DYNAMIC_SPOTLIGHT_VS(skinned);						// midnight_spotlight_skinned_vs
BUILD_DYNAMIC_SPOTLIGHT_VS(rigid_boned);					// midnight_spotlight_rigid_boned_vs
BUILD_DYNAMIC_SPOTLIGHT_VS(rigid_blendshaped);				// midnight_spotlight_rigid_blendshaped_vs
BUILD_DYNAMIC_SPOTLIGHT_VS(skinned_blendshaped)				// midnight_spotlight_skinned_blendshaped_vs


void midnight_spotlight_transparents_default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos),
	in s_pixel_shader_input pixel_shader_input,
	in s_platform_pixel_input platformInput,
	out float4 out_color: SV_Target0)
{
	// get the lightprobe constants
	s_vmf_sample_data vmf_sample_vertex;
	sample_lightprobe_constants(vmf_sample_vertex);

	s_shader_data shader_data= init_shader_data(pixel_shader_input, platformInput, LM_DYNAMIC_LIGHTING);
	shader_data.common.shaderPass = SP_DYNAMIC_LIGHTING;

	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	// add the spot light to the light list
	add_spotlight_to_light_data(shader_data.common.lighting_data, shader_data.common.position, shader_data.common.shadowProjection, pixel_pos);

	// Run the user shader to get the lit pixel value
	out_color = pixel_lighting(pixel_shader_input, shader_data);
	out_color = apply_exposure(out_color);
}

// use the same vertex shaders for the transparent spotlight as we did for the regular one
#define midnight_spotlight_transparents_world_vs 				midnight_spotlight_world_vs
#define midnight_spotlight_transparents_rigid_vs 				midnight_spotlight_rigid_vs
#define midnight_spotlight_transparents_skinned_vs 				midnight_spotlight_skinned_vs
#define midnight_spotlight_transparents_rigid_boned_vs 			midnight_spotlight_rigid_boned_vs
#define midnight_spotlight_transparents_rigid_blendshaped_vs 	midnight_spotlight_rigid_blendshaped_vs
#define midnight_spotlight_transparents_skinned_blendshaped_vs 	midnight_spotlight_skinned_blendshaped_vs


#endif 	// !defined(__ENTRYPOINTS_STATIC_LIGHTING_FXH)