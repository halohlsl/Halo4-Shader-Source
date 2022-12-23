#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_screenPosScaleBias	k_cui_pixel_shader_color0
#define k_offset				k_cui_pixel_shader_color1
#define k_slicePositions		k_cui_pixel_shader_color2
#define k_sliceGuides			k_cui_pixel_shader_color3

#define k_opacity				k_cui_pixel_shader_scalar0
#define k_alphaMaskThreshold	k_cui_pixel_shader_scalar1

float4 filterTex2D(in texture_sampler_2d source_sampler, in float4 sampler_transform, in float2 texcoord)
{
	float4 color = sample2D(source_sampler, texcoord);

	// For the purposes of filtering, we want to use the color in non-premultiplied alpha form; so for textures
	// that use premultiplied alpha, we convert to non-premultiplied alpha.
	color.a = color.a * (-1 * sampler_transform.x) + (1 - sampler_transform.y);

	return color;
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float2 firstSliceUV =	(input.texcoord.xy / k_slicePositions.xy) * k_sliceGuides.xy;
	float2 thirdSliceUV =	(((input.texcoord.xy - k_slicePositions.zw) / (1.0 - k_slicePositions.zw)) * (1.0 - k_sliceGuides.zw)) + k_sliceGuides.zw;
	float2 secondSliceUV =	(((input.texcoord.xy - k_slicePositions.xy) / (k_slicePositions.zw - k_slicePositions.xy)) * (k_sliceGuides.zw - k_sliceGuides.xy)) + k_sliceGuides.xy;

	float2 firstSliceDecisionMaker = step(input.texcoord, k_slicePositions.xy); // 1 for left/top slice
	float2 thirdSliceDecisionMaker = step(k_slicePositions.zw, input.texcoord); // 1 for right/bottom slice

	float2 slicedTexCoord = lerp(
		lerp(secondSliceUV, thirdSliceUV, thirdSliceDecisionMaker),
		firstSliceUV,
		firstSliceDecisionMaker);

	float4 sourceColor = filterTex2D(source_sampler0, k_cui_sampler0_transform, slicedTexCoord);

	// Calculate the sample position for the resolved render target texture
	float2 sourceTexCoord = (k_offset.xy + input.screenPos.xy - k_screenPosScaleBias.xy) / k_screenPosScaleBias.zw;
	float4 blurColor = filterTex2D(source_sampler2, k_cui_sampler2_transform, sourceTexCoord);

	float blurOpacity = k_opacity * saturate(sourceColor.a / k_alphaMaskThreshold);

	float4 color = float4(blurColor.rgb * blurOpacity, 1.0 - blurOpacity);
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

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
