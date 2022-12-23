#if !defined(__ENTRYPOINTS_CGFX_FXH)
#define __ENTRYPOINTS_CGFX_FXH

#include "entrypoints/common.fxh"

#if defined(cgfx)

#include "lighting/lighting.fxh"

// CG Shader support
void combined_vs(
	in s_rigid_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output)
{
	//output= (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_rigid, input, output, local_to_world_transform, out_position);
	output.texcoord= float4(input.texcoord.xy, input.texcoord1.xy);
}

void combined_opaque_ps(
	in s_pixel_shader_input pixel_shader_input,
	out float4 out_color: SV_Target0)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	// add the maya lights to the light list
	add_maya_lights_to_light_data(shader_data.common.lighting_data);

	out_color= pixel_lighting(pixel_shader_input, shader_data);
	out_color= apply_exposure(out_color);

	// Maya likes the alpha to be 1 for swatch rendering, etc.
	out_color.a= 1;
}

void combined_albedo_ps(
	in s_pixel_shader_input pixel_shader_input,
	out float4 out_color: SV_Target0)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	//shader_data.common.normal = normalize(shader_data.common.normal);

	// add the maya lights to the light list
	//add_maya_lights_to_light_data(shader_data.common.lighting_data);

	out_color.rgb = shader_data.common.albedo.rgb;
	out_color= apply_exposure(out_color);

	// Maya likes the alpha to be 1 for swatch rendering, etc.
	out_color.a= 1;
}


void combined_alpha_ps(
	in s_pixel_shader_input pixel_shader_input,
	out float4 out_color: SV_Target0)
{
	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	pixel_pre_lighting(pixel_shader_input, shader_data);

	// Need to normalize the normal (usually done on encode into normal buffer)
	shader_data.common.normal = normalize(shader_data.common.normal);

	// add the maya lights to the light list
	add_maya_lights_to_light_data(shader_data.common.lighting_data);

	out_color= pixel_lighting(pixel_shader_input, shader_data);
	out_color= apply_exposure(out_color);
}

#endif

#endif 	// !defined(__ENTRYPOINTS_CGFX_FXH)