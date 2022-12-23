#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "screenshot_memexport_registers.fxh"


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

float4 default_ps_tex(const in s_vertex_output_screen_tex input, in SCREEN_POSITION_INPUT(pos)) : SV_Target
{
	float2 pixel_coord= pos.xy * vpos_to_pixel_xform.xy + vpos_to_pixel_xform.zw;
	int pixel_index= min(pixel_coord.y * export_info.x + pixel_coord.x, export_info.y);

	// sample source
	float2 source_coord= pixel_coord.xy * pixel_to_source_xform.xy + pixel_to_source_xform.zw;	
	float4 source= sample2D(ps_source_sampler, source_coord);

	// sample background
	float4 result= source;
#ifdef pc
	source += sample2D(ps_background_sampler, input.texcoord);
#else

	// grab exact background pixel
	float4 background;
	asm {
		tfetch2D	background, pixel_coord, ps_background_sampler, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
	};

	result += background;
	result.rgb= result.bgr;

	// mem-export!
	const float4 k_offset_const= { 0, 1, 0, 0 };
	asm {
		alloc export=1
		mad eA, pixel_index, k_offset_const, export_stream_constant
		mov eM0, result
	};

#endif
	return result;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}



