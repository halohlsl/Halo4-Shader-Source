#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"
#include "cui_transform.fxh"		// adds the default vertex shader


// ==== SHADER DOCUMENTATION
// 
// ---- COLOR OUTPUTS
// k_cui_pixel_shader_color0= {xy:pivot origin, z:is clockwise}
// k_cui_pixel_shader_color1= {x:start angle, y:stop angle}
// k_cui_pixel_shader_color2= texture coordinate bounds
// k_cui_pixel_shader_color3= unused
// 
// ---- SCALAR OUTPUTS
// k_cui_pixel_shader_scalar0= current meter value in radians (0 .. 2*pi)
// k_cui_pixel_shader_scalar1= meter minimum value in radians (0 .. 2*pi)
// k_cui_pixel_shader_scalar2= meter maximum value in radians (0 .. 2*pi)
// k_cui_pixel_shader_scalar3= unused
//
// ---- BITMAP CHANNELS
// A: alpha (except for empty meter regions, which are transparent)
// R: intensity
// G: unused
// B: meter mask

#define k_pivotSettings k_cui_pixel_shader_color0
#define k_meterAngles k_cui_pixel_shader_color1
#define k_texcoordBounds k_cui_pixel_shader_color2
#define k_currentMeterValue k_cui_pixel_shader_scalar0
#define k_minMeterValue k_cui_pixel_shader_scalar1
#define k_maxMeterValue k_cui_pixel_shader_scalar2

#define k_uvToPixels 256.0
#define tau (2*pi)

float4 BuildResult(float2 texcoord)
{
	float4 bitmapResult = sample2D(source_sampler0, texcoord);

	// Result rgb channels use the intensity mask from the red channel replicated across the red green and blue channels.
	float4 result = float4(bitmapResult.rrr, bitmapResult.a);

	// Calculate the angle from the current fragment to the pivot point, relative to the starting angle
	float2 relativeTexcoord = float2(texcoord.x-k_pivotSettings.x, texcoord.y-k_pivotSettings.y);
	float angle = atan2(-relativeTexcoord.y, relativeTexcoord.x);
	angle = lerp(angle, angle+tau, step(angle, 0.0));
	angle = angle - k_meterAngles.x;
	angle = fmod(angle, tau);
	angle = lerp(angle, angle+tau, step(angle, 0.0));
	angle *= tau / abs(k_meterAngles.y - k_meterAngles.x);

	// Invert the angle if the meter fills clockwise
	angle = lerp(angle, tau-angle, k_pivotSettings.z);

	// Calculate the radius and arc length for the current fragment
	float radius = length(relativeTexcoord);
	float arcLength = (radius * angle) * k_uvToPixels;

	float meterArcLength = ((radius * k_currentMeterValue) * k_uvToPixels) + 1.0;
	float maxArcLength = ((radius * k_maxMeterValue) * k_uvToPixels) + 1.0;
	float minArcLength = ((radius * k_minMeterValue) * k_uvToPixels) - 1.0;

	result.a *= saturate(meterArcLength - arcLength) *	// Clip the fragment to the current meter value
		saturate(maxArcLength - arcLength) *			// Clip the fragment to the max meter value
		saturate(arcLength - minArcLength);				// Clip the fragment to the min meter value

	return result;
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 result= BuildResult(input.texcoord);

	// Final rgb result is the user color multiplied by the bitmap's intensity channel, and the bitmap's
	// alpha channel multiplied by the user alpha.

	float4 tint = cui_linear_to_gamma2(k_cui_pixel_shader_tint);

	result.rgb = tint.rgb * result.r;
	result.a *= k_cui_pixel_shader_tint.a;

	return cui_convert_to_premultiplied_alpha(result, k_cui_sampler0_transform) * ps_scale;
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
