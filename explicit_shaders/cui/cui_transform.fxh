#if !defined(__CUI_TRANSFORM_FXH)
#define __CUI_TRANSFORM_FXH

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "cui_registers.fxh"
#include "cui_curvature_transform.fxh"

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
    float2 screenPos:		TEXCOORD1;
	float4 color:			COLOR0;
};

s_screen_vertex_output default_vs(
	const in s_screen_vertex input)
{
	s_screen_vertex_output output;

	output.texcoord= input.texcoord;
	output.color= input.color;

	float4 position= float4(input.position, 0.0F, 1.0F);

	float3 model_view_position= mul(position, k_cui_vertex_shader_constant_model_view_matrix);
	output.position= mul(float4(model_view_position, 1.0F), k_cui_vertex_shader_constant_projection_matrix);

	output.screenPos.xy = output.position.xy / output.position.w;

	return output;
}

s_screen_vertex_output curved_cui_vs(
	const in s_screen_vertex input)
{
	s_screen_vertex_output output;

	output.texcoord = input.texcoord;
	output.color= input.color;

	// 'position' will be screenspace pixel coordinates, with the origin in the center of the screen, and top-left
	// will be (-halfScreenWidth,+halfScreenHeight).
	float3 position = mul(float4(input.position, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix).xyz;

	// Convert to screenspace pixel coordinates, with the origin at the top-left of the screen.
	position.y = -position.y;
	position.xy += k_cui_screen_size.xy * 0.5f;

	// Input for chud_virtual_to_screen() needs to be screenspace pixels, where the origin is at the top-left of the
	// screen.
    output.position = chud_virtual_to_screen(position.xy);
	output.screenPos.xy = output.position.xy / output.position.w;

	return output;
}

#endif	// __CUI_TRANSFORM_FXH
