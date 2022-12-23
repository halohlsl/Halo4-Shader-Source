#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"



LOCAL_SAMPLER2D(ps_source_sampler, 0);


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
#if defined(xenon)
	output.texcoord.xy = input.texcoord * vs_texture_size.zw + float2(0.25, 0.25);
	output.texcoord.zw = output.texcoord.xy;
	output.texcoord.z /= 80.0f;
#else
	output.texcoord=	input.texcoord.xyxy;
#endif
	return output;
}


// 360 shader
// do NOT use VPOS here, it forces 3 interpolants, and we can get away with 2
// single target restore runs at nearly full rate of 2 quads/clock
// VPOS forces halfrate and will make this interpolant bound.

float4 default_ps(s_screen_vertex_output input) : SV_Target0
{
#if !defined(xenon)
 	return 0.0f;
#else	// !defined(xenon)
	// exchange every other 40-pixel column
	float4 pixel_coordinates = input.texcoord;

	float column = pixel_coordinates.z;
	float halfcolumn = frac(column);

	[flatten]
	if (halfcolumn >= 0.5)
		pixel_coordinates.x -= 40;
	else
		pixel_coordinates.x += 40;

	float4 result;
	asm
	{
		tfetch2D result, pixel_coordinates.xy, ps_source_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
	return result.bbbb;		// stencil is stored in the blue channel
#endif	// !defined(xenon)
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}




