
#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "../copy/crop_registers.fxh"
#include "screenshot_display_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float2 texcoord= transform_texcoord(input.texcoord, ps_texcoord_xform);
 	float4 color= sample2D(ps_screenshot_source_sampler, texcoord);
 	float crop= step(ps_crop_bounds.x, texcoord.x) * step(texcoord.x, ps_crop_bounds.z) * step(ps_crop_bounds.y, texcoord.y) * step(texcoord.y, ps_crop_bounds.w);

	float3 corrected=	pow(color.bgr, ps_swap_color_channels.w);
	color.rgb = lerp(color.rgb, corrected, ps_swap_color_channels.x);

	color.a = 1.0f / 32.0f;					// alpha must be 1 (with exponent bias correction)

 	return color * crop;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



