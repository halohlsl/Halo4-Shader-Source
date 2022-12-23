#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "debug_light_registers.fxh"

void default_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float3 world_position : TEXCOORD0)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;	
	float4 local_to_world_transform[3];
#if !defined(PROJECIVE_TRANSFORM)
	apply_transform_position_only(deform_tiny_position, input, output, local_to_world_transform, out_position);
#else
	apply_transform_position_only(deform_tiny_position_projective, input, output, local_to_world_transform, out_position);
#endif
	world_position = input.position;
}



float3 calc_normal_from_position(
	in float3 fragment_position_world)
{
	float3 dBPx= ddx(fragment_position_world);		// worldspace gradient along pixel x direction
	float3 dBPy= ddy(fragment_position_world);		// worldspace gradient along pixel y direction
	float3 bump_normal= -normalize( cross(dBPx, dBPy) );	

	return bump_normal;
}

float4 default_ps(
	in float4 screen_position : SV_Position,
	in float3 world_position : TEXCOORD0) : SV_Target
{
#if !defined(xenon)
 	float4 color= float4(1.0f, 1.0f, 0.0f, 1.0f);
#else	// !defined(xenon)
	float3 normal=	calc_normal_from_position(world_position);
	float4 color=	float4(normal.xyz * 0.5f + 0.5f, 1.0);
#endif	// !defined(xenon)

	color.rgb = ps_scale.rgb * 0.6f + 0.4f * color.rgb;

	return apply_exposure(color);
}



BEGIN_TECHNIQUE _default
{
	pass _default
	{
		SET_PIXEL_SHADER(default_ps());
	}
	pass tiny_position
	{
		SET_VERTEX_SHADER(default_vs());
	}
}


