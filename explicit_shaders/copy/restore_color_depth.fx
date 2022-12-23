#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


// Allow this shader to be used in a variety of ways
#ifdef ONLY_DEPTH
	#define DO_COLOR 0
	#define DO_DEPTH 1
	#define OUTPUT_COUNT 1
	#define OUTPUT_DEPTH 0
#elif ONLY_COLOR
	#define DO_COLOR 1
	#define DO_DEPTH 0
	#define OUTPUT_COUNT 1
	#define OUTPUT_COLOR 0
#else
	#define DO_COLOR 1
	#define DO_DEPTH 1
	#define OUTPUT_COUNT 2
	#define OUTPUT_DEPTH 0
	#define OUTPUT_COLOR 1
#endif


LOCAL_SAMPLER2D(ps_color_sampler, 0);
LOCAL_SAMPLER2D(ps_depth_sampler, 2);

struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

struct pixel_output
{
	float4 color[OUTPUT_COUNT] : SV_Target0;
};


s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position = float4(input.position.xy, 1.0, 1.0);
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

pixel_output default_ps_tex(s_vertex_output_screen_tex input)
{
	pixel_output out_colors;

#if !defined(xenon)
#if DO_DEPTH
 	out_colors.color[OUTPUT_DEPTH] = sample2D(ps_depth_sampler, input.texcoord);
#endif	// DO_DEPTH
#if DO_COLOR
	out_colors.color[OUTPUT_COLOR] = sample2D(ps_color_sampler, input.texcoord);
#endif	// DO_COLOR

#else	// !defined(xenon)

	float4 pixel_coordinates = input.texcoord;

#if DO_COLOR
	float4 ldr_color;
	asm
	{
		tfetch2D ldr_color, pixel_coordinates.xy, ps_color_sampler, UnnormalizedTextureCoords = true, UseComputedLOD = false, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
	out_colors.color[OUTPUT_COLOR] = ldr_color;
#endif	// DO_COLOR

#if DO_DEPTH
	float4 depth_color;

	float column = pixel_coordinates.z;
	float halfcolumn = frac(column);

	[flatten]
	if (halfcolumn >= 0.5)
		pixel_coordinates.x -= 40;
	else
		pixel_coordinates.x += 40;

	asm
	{
		tfetch2D depth_color.zyxw, pixel_coordinates.xy, ps_depth_sampler, UnnormalizedTextureCoords = true, UseComputedLOD = false, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
	out_colors.color[OUTPUT_DEPTH] = depth_color;
#endif	// DO_DEPTH

#endif	// !defined(xenon)

	return out_colors;
}






BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}

