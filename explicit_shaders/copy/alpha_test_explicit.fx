#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "atmosphere/atmosphere.fxh"
#include "alpha_test_explicit_registers.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

#include "entrypoints/common.fxh"

void default_world_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	s_vertex_shader_output output= (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_world, input, output, local_to_world_transform, out_position);
	texcoord = input.texcoord.xyxy;

	s_shader_output_atmosphere atmospherics;
	ComputeAtmosphericScattering(
		vs_atmosphere_fog_table,
		input.position.xyz - vs_view_camera_position,		// viewVector
		input.position.xyz,									// worldPosition
		atmospherics.inscatter.rgb,							// inscatter
		atmospherics.extinction.x,							// extinction
		atmospherics.extinction.y,							// desaturation
		false,
		false);

	extinction = atmospherics.extinction.x * vs_lighting.rgb;
	inscatter = float3(0, 0, 0);
}


float4 default_ps(
	in float4 position : SV_Position,
	in float2 texcoord : TEXCOORD0,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1) : SV_Target
{
	float4 color = sample2D(ps_basemap_sampler, texcoord);
	clip(color.a - 0.5f);

	color.rgb = (color.rgb * extinction + inscatter);
	return apply_exposure(color);
}


BEGIN_TECHNIQUE _default
{
	pass world
	{
		SET_VERTEX_SHADER(default_world_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

