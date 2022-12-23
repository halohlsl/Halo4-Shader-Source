#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_source_sampler,		0);


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
	float4 color;
#if !defined(xenon)
 	color= sample2D(ps_source_sampler, input.texcoord);
#else // xenon
	float2 texcoord0 = input.texcoord + ps_pixel_size.xy * 0.25f;
	float2 texcoord1 = input.texcoord - ps_pixel_size.xy * 0.25f;
	float4 tex0, tex1;
	asm
	{
		tfetch2D tex0, texcoord0, ps_source_sampler, MagFilter = linear, MinFilter = linear, MipFilter = point, AnisoFilter = disabled
		tfetch2D tex1, texcoord1, ps_source_sampler, MagFilter = linear, MinFilter = linear, MipFilter = point, AnisoFilter = disabled
	};
	color.rgb= (tex0.rgb + tex1.rgb) * 0.5f;
	color.a= (tex0.a + tex1.a) * 0.5f;

#endif	
 	return color * ps_scale;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


