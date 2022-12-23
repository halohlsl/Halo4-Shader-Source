#if !defined(__ENTRYPOINTS_LIGHT_CONE_FXH)
#define __ENTRYPOINTS_LIGHT_CONE_FXH

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "fx/blend_modes.fxh"
#include "fx/fx_parameters.fxh"
#include "fx/fx_functions.fxh"

#define DEPTH_FADE_SWITCH "depth_fade_enabled"
#include "depth_fade.fxh"

DECLARE_BOOL_WITH_DEFAULT(depth_fade_enabled, "Depth Fade Enabled", "", false);
#include "next_bool_parameter.fxh"

#include "light_cone_registers.fxh"

struct VertexOutput
{
    float4 position : SV_Position;
    float4 color : COLOR0;
    float3 texcoord_depth : TEXCOORD0;
};

VertexOutput DefaultVS(const in s_screen_vertex input)
{
	VertexOutput output;
	
	float2 localPosition = input.position * vs_size;
	
	float3 screenLeft = cross(vs_direction, normalize(vs_position - vs_view_camera_position));
	float sinViewAngle = length(screenLeft);
	screenLeft /= sinViewAngle;
	float3 worldPosition = vs_position + localPosition.x * screenLeft + localPosition.y * vs_direction;
	
	float depth = dot(vs_view_camera_backward, vs_view_camera_position - worldPosition);

	output.position = mul(float4(worldPosition, 1.0f), vs_view_view_projection_matrix);
	
	output.texcoord_depth = float3(input.texcoord, depth);
	
	output.color = vs_color;
	
	float viewAngle = asin(sinViewAngle);
	output.color.a *= saturate((viewAngle - vs_angleFadeRangeCutoff.y) / (vs_angleFadeRangeCutoff.x - vs_angleFadeRangeCutoff.y));
	
	output.color.rgb *= vs_bungie_additive_scale_and_exposure.y;
	
	return output;
}

float4 DefaultPS(
	in VertexOutput vertexOutput
#if defined(xenon) || (DX_VERSION == 11)
	, SCREEN_POSITION_INPUT(fragment_position)
#endif // defined(xenon)
	) : SV_Target
{
	float4 color = PixelComputeColor(vertexOutput.texcoord_depth.xy);
	
#if defined(xenon) || (DX_VERSION == 11)
	fragment_position.xy += ps_tiling_vpos_offset.xy;
	
	[branch]
	if (depth_fade_enabled)
	{
		color.a *= ComputeDepthFade(fragment_position * psDepthConstants.z, vertexOutput.texcoord_depth.z);
	}
#endif // defined(xenon)
	
	return ps_apply_exposure(color, vertexOutput.color, float3(0, 0, 0), 0);
}

#endif 	// !defined(__ENTRYPOINTS_LIGHT_CONE_FXH)