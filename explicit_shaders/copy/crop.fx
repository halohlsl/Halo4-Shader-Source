#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "crop_registers.fxh"


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
	float4 color= sample2D(ps_source_sampler, texcoord);
	float crop= step(ps_crop_bounds.x, texcoord.x) * step(texcoord.x, ps_crop_bounds.z) * step(ps_crop_bounds.y, texcoord.y) * step(texcoord.y, ps_crop_bounds.w);
	return color * ps_scale * crop;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}




