#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_stroke_color k_cui_pixel_shader_color0
#define k_width k_cui_pixel_shader_scalar0
#define k_position k_cui_pixel_shader_scalar1

#define k_edge_softness 0.1
// ### v-miroll $PERFORMANCE: This should really be sent down from the CPU rather than being recalculated every fragment.
// <lazy> It's reasonably fast now, which is why I haven't done it yet. <\lazy>
#define k_inner_threshhold lerp( k_edge_softness, (1.0 - k_edge_softness) - (k_width * (1.0 - k_edge_softness * 2.0)), k_position )
#define k_outer_threshhold lerp( k_edge_softness, (1.0 - k_edge_softness) - (k_width * (1.0 - k_edge_softness * 2.0)), 1.0 - k_position )

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// fetch the blurred sample
	float4 blurColor = sample2D(source_sampler1, input.texcoord);

	// Mask the blurred sample to generate an antialiased solid outline, using the threshholds to
	// specify the level of antialiasing.
	float strokeMask = smoothstep(saturate(k_outer_threshhold-k_edge_softness), saturate(k_outer_threshhold+k_edge_softness), blurColor.a);
	strokeMask *= smoothstep(saturate(k_inner_threshhold-k_edge_softness), saturate(k_inner_threshhold+k_edge_softness), 1.0 - blurColor.a);

	// Apply color tint
	float4 color = cui_linear_to_gamma2(k_stroke_color * k_cui_pixel_shader_tint * input.color * strokeMask);

	// Convert to premultiplied alpha
	color.rgb *= color.a;
	color.a = 1.0 - color.a;

	return color*ps_scale;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
