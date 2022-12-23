#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

#define MAX_COLOR_GRADING_TEXTURES 0

#define ps_hologram_screen_coverage ps_material_generic_parameters[0]
#define ps_hologram_texcoords		ps_material_generic_parameters[1]

// skip three textures
#include "next_texture.fxh"
#include "next_texture.fxh"
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(color_tint,		"Color Tint", "", float3(0.8705883,0.2588235,0.1058824));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_tint_amount, "Color Tint Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"


DECLARE_SAMPLER(noise_overlay_1,	"Noise Overlay 1", "Noise Overlay 1", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(noise_filter_1,	"Noise Filter", "", float3(0.5, 0.5, 0.5));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_intensity_1,	"Noise Intensity", "", 0, 1, 0.4);
#include "used_float.fxh"


DECLARE_SAMPLER(noise_overlay_2,	"Noise Overlay 2", "Noise Overlay 2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(noise_filter_2,	"Noise Filter", "", float3(0.5, 0.5, 0.5));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_intensity_2,	"Noise Intensity", "", 0, 1, 0.4);
#include "used_float.fxh"


DECLARE_SAMPLER(scanlines_map,		"Scanline Map", "scanlines_map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scanlines_intensity,	"Scanline Intensity", "", 0, 1, 1);
#include "used_float.fxh"


DECLARE_SAMPLER(distortion_1_map,	"Distortion Map 1", "Distortion Map 1", "shaders/default_bitmaps/bitmaps/color_black_alpha_black.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distort1_amount,		"Distort 1 Amount", "Distort 1 Amount", 0, 10, 0.05);
#include "used_float.fxh"


DECLARE_SAMPLER(distortion_2_map, 	"Distortion Map 2", "Distortion Map 2", "shaders/default_bitmaps/bitmaps/color_black_alpha_black.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distort2_amount,		"Distort 2 Amount", "Distort 2 Amount", 0, 10, 0.05);
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(distort_threshold_min,		"Distort Threshold Min", "Distort Threshold Min", 0, 10, 0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distort_threshold_max,		"Distort Threshold Max", "Distort Threshold Max", 0, 10, 4);
#include "used_float.fxh"





#include "postprocessing/postprocess_textures.fxh"
#include "final_composite_functions.fxh"
#include "final_composite_shared_registers.fxh"
#include "operations/color.fxh"


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


float4 default_ps(const in s_screen_vertex_output input) : SV_Target0
{
	float2 alignedTexcoord = input.texcoord - ps_player_window_constants.zw * ps_hologram_screen_coverage.xy;
	alignedTexcoord /= ps_player_window_constants.zw * ps_hologram_screen_coverage.zw;

	float2 distortion_texcoord = input.texcoord;

	// sample bloom buffer
	float4 bloom    = sample2D(ps_bloom_sampler,  input.texcoord);

	// Distortion effect 1 - cortanas horixontal jump distortion
	float2 distortion1_offset = sample2D(distortion_1_map, transform_texcoord(alignedTexcoord, distortion_1_map_transform)).xy;
	float2 distortion2_offset = sample2D(distortion_2_map, transform_texcoord(alignedTexcoord, distortion_2_map_transform)).xy;

	// Scale the distortion amounts by the screen proportions and overall intensity
	distortion1_offset *= distort1_amount * ps_player_window_constants.zw * ps_hologram_screen_coverage.zw;
	distortion2_offset *= distort2_amount * ps_player_window_constants.zw * ps_hologram_screen_coverage.zw;

	// Apply the distortion, keeping it within the valid portion of the texture
	distortion_texcoord += (distortion1_offset + distortion2_offset) * float_threshold(bloom.a, distort_threshold_min, distort_threshold_max);
	distortion_texcoord = clamp(distortion_texcoord, ps_hologram_texcoords.xz, ps_hologram_texcoords.yw);

	// sample combined buffer with distortion coords
	float4 combined = sample2D(ps_surface_sampler, distortion_texcoord);


	// Sample noise and scanline textures
	float4 noise1 	= sample2D(noise_overlay_1, transform_texcoord(alignedTexcoord, noise_overlay_1_transform)).rrrr;
	float4 noise2 	= sample2D(noise_overlay_2, transform_texcoord(alignedTexcoord, noise_overlay_2_transform)).rrrr;
	noise2 = lerp(0.5, noise2, noise2.r);

	float4 static_scanlines = sample2D(scanlines_map, transform_texcoord(alignedTexcoord, scanlines_map_transform)).rrrr;


	// Modulate base plates alpha by the slow moving scanlines before bloom
	combined.a *= lerp(0.5, noise_filter_1 * noise1, noise_intensity_1) * 2;
	combined.a *= lerp(0.5, noise_filter_2 * noise2, noise_intensity_2) * 2;



	float4 blend = 0.0f;

	// Screen the base plate and bloom
	blend = max(combined, 1 - saturate(1 - combined) * saturate(1 - bloom));

	// colot tint 
	float topLuma = color_luminance(color_tint);
	float bkgLuma = color_luminance(blend.rgb);
	
	topLuma  = pow(topLuma, 0.5);    
    bkgLuma = pow(bkgLuma, 0.5);   
	
	float luminance = saturate(bkgLuma - topLuma);
	
	float3 blendColor = color_tint;
	blendColor += bkgLuma;
	blendColor *= bkgLuma * blendColor;

	// red shift control
	blend.rgb = lerp(blend.rgb, blendColor, color_tint_amount);

	
	// Modulate current blend by static scanlines, effects rgb only
	blend.rgb *= lerp(1, static_scanlines.rgb, scanlines_intensity);

	// Modulate current blend by subtle tele noise pattern
	blend.rgb *= lerp(1, noise_filter_2 * noise2, noise_intensity_2);



	
	
	// Apply filmic tone curve
	float4 result = blend;
	result.rgb = ApplyFilmicToneCurve(result.rgb);


	// Premultiy new alpha composite
	result.rgb *= result.a;
	result.a = combined.a;


	return result;
}




// _explicit_shader_final_composite
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
