#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "core/core_functions.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_surface_sampler,	0);


#define DARK_COLOR_MULTIPLIER ps_exposure.g


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texCoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position =	float4(input.position.xy, 0.0, 1.0);
	output.texCoord =	input.texcoord;
	return output;
}

[reduceTempRegUsage(3)]
float4 default_ps(s_screen_vertex_output input) : SV_Target
{
#if !defined(xenon)
	float3 color = 0.00000001f;			// hack to keep divide by zero from happening on the nVidia cards
#else
	float3 color = 0.0f;
#endif
	
	// this is a 6x6 gaussian filter (slightly better than 4x4 box filter)
	color += 0.25f * Sample2DOffset(ps_surface_sampler, input.texCoord, -2, -2);
	color += 0.50f * Sample2DOffset(ps_surface_sampler, input.texCoord, +0, -2);
	color += 0.25f * Sample2DOffset(ps_surface_sampler, input.texCoord, +2, -2);
	color += 0.50f * Sample2DOffset(ps_surface_sampler, input.texCoord, -2, +0);
	color += 1.00f * Sample2DOffset(ps_surface_sampler, input.texCoord, +0, +0);
	color += 0.50f * Sample2DOffset(ps_surface_sampler, input.texCoord, +2, +0);
	color += 0.25f * Sample2DOffset(ps_surface_sampler, input.texCoord, -2, +2);
	color += 0.50f * Sample2DOffset(ps_surface_sampler, input.texCoord, +0, +2);
	color += 0.25f * Sample2DOffset(ps_surface_sampler, input.texCoord, +2, +2);
	color /= 4.0f;

	return float4(color.rgb, 1.0f);
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


