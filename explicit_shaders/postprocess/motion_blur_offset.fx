#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "../copy/displacement_registers.fxh"
#include "motion_blur_offset_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 iterator0:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position =	float4(input.position.xy, 1.0, 1.0);

	float2 uncentered_texture_coords = input.position.xy * float2(0.5f, -0.5f) + 0.5f;		// uncentered means (0, 0) is the center of the upper left pixel
	float2 pixel_coords =	uncentered_texture_coords * vs_resolution_constants.xy + 0.5f;	// pixel coordinates are centered [0.5, resolution-0.5]
	float2 texture_coords =	uncentered_texture_coords + 0.5f * vs_resolution_constants.zw;	// offset half a pixel to center these texture coordinates

	output.iterator0.xy = (texture_coords - 0.5) * float2(2, -2);
	output.iterator0.zw = texture_coords;

	return output;
}


//[reduceTempRegUsage(4)]
float4 default_ps(in s_screen_vertex_output input) : SV_Target0
{
#if defined(xenon)

	float4 cur_proj = float4(input.iterator0.xy, sample2D(ps_distortion_depth_buffer, input.iterator0.zw).r, 1.0);
	float4 last_proj = mul(cur_proj, transpose(ps_combined3[1]));

	// perspective divide to get back to homogenous screen-space coordinates
	last_proj.xy /= last_proj.w;

	float2 offset = (cur_proj.xy - last_proj.xy);

	// Take the cube root of the value to increase precision in low motion
//	offset = sign(offset) * pow(offset, 1.0f / 3.0f);

	return float4(0.5 + 0.5 * offset, 0, 0);


#else // xenon

	return float4(0.5, 0.5, 0, 0);

#endif // xenon
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



