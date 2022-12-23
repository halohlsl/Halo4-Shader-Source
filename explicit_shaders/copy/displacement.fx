#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "displacement_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 iterator0:		TEXCOORD0;
};

#if DX_VERSION == 11
	static const float half_texel_offset = 0;
#else	
	static const float half_texel_offset = 0.5f;
#endif

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position =	float4(input.position.xy, 1.0, 1.0);	

	float2 uncentered_texture_coords = input.position.xy * float2(0.5f, -0.5f) + 0.5f;					// uncentered means (0, 0) is the center of the upper left pixel
	float2 pixel_coords =	uncentered_texture_coords * vs_resolution_constants.xy + half_texel_offset;	// pixel coordinates are centered [0.5, resolution-0.5]
	float2 texture_coords =	uncentered_texture_coords + half_texel_offset * vs_resolution_constants.zw;	// offset half a pixel to center these texture coordinates

	output.iterator0.xy = pixel_coords;
	output.iterator0.zw = texture_coords;

	return output;
}


float4 tex2D_unnormalized(texture_sampler_2d texture_sampler, float2 unnormalized_texcoord)
{
	float4 result;
	
#if defined(xenon)
	asm
	{
		tfetch2D result, unnormalized_texcoord, texture_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = linear, MipFilter = linear, AnisoFilter = disabled, UseComputedLOD = false
	};
#else
	result= sample2D(texture_sampler, (unnormalized_texcoord + half_texel_offset) * ps_screen_constants.xy);
#endif

	return result;
}


float4 default_ps(in s_screen_vertex_output input) : SV_Target0
{
	// unpack iterators
	float2 pixel_coords = input.iterator0.xy;
	float2 texture_coords = input.iterator0.zw;

	float2 displacement = sample2D(ps_displacement_sampler, texture_coords).xy * ps_distort_constants.xy + ps_distort_constants.zw;

	pixel_coords = clamp(pixel_coords + displacement, ps_window_bounds.xy, ps_window_bounds.zw);

	float4 displaced_pixel = tex2D_unnormalized(ps_ldr_buffer, pixel_coords);

	return displaced_pixel;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



