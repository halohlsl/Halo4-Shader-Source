#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader


#define k_roundingRadii k_cui_pixel_shader_color0

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color = cui_tex2D(input.texcoord);

#if (! defined(pc)) || (DX_VERSION == 11)
	float2 texcoord = input.texcoord;
	
#ifdef xenon
	float4 gradients;
	asm {
		getGradients gradients, texcoord, source_sampler0
	};
#else
	float4 gradients = GetGradients(texcoord);
#endif

	float2 maskTexcoord = (input.texcoord - k_cui_pixel_shader_authored_bounds.xy) /
		(k_cui_pixel_shader_authored_bounds.zw - k_cui_pixel_shader_authored_bounds.xy);

	// Discard the fragment if outside the authored bounds. This is equivalent to forcing clipChildren==true
	// when applied to containers.
	clip(maskTexcoord);
	clip(float2(1.0, 1.0) - maskTexcoord);

	// Calculate the length of the ddx and ddy of texcoord 0
	float2 gradientLengths = float2(length(gradients.xy), length(gradients.zw));

	// Save of the center of the pseudo-circles used to scribe the corners
	float2 cornerOriginTL = k_roundingRadii.xx;
	float2 cornerOriginTR = k_roundingRadii.yy;
	float2 cornerOriginBR = k_roundingRadii.zz;
	float2 cornerOriginBL = k_roundingRadii.ww;

	// Calculate the fragment position relative to each of the four corners
	float2 relativePosTL = maskTexcoord / gradientLengths;
	float2 relativePosTR = float2( 1.0f - maskTexcoord.x, maskTexcoord.y ) / gradientLengths;
	float2 relativePosBR = float2( 1.0f - maskTexcoord.x, 1.0f - maskTexcoord.y ) / gradientLengths;
	float2 relativePosBL = float2( maskTexcoord.x, 1.0f - maskTexcoord.y ) / gradientLengths;

	// Calculate the distance of the fragment to each of the four corners
	float4 cornerDistances = float4(
		length( relativePosTL - cornerOriginTL ),
		length( relativePosTR - cornerOriginTR ),
		length( relativePosBR - cornerOriginBR ),
		length( relativePosBL - cornerOriginBL ) );

	// Calculate clip value for rounded corners, where 0.0 means opaque, and 1.0 means transparent.
	// 'smoothstep' will return 0.0 for distances that are closer than 'k_roundingRadii', and it
	// will return 1.0 for distances that are further than 'k_roundingRadii'. The transition between
	// 0.0 and 1.0 is softened by a hermite curve over a single pixel boundary.
	float4 roundingVector = smoothstep(
		k_roundingRadii,
		k_roundingRadii+float4(1.0f,1.0f,1.0f,1.0f),
		cornerDistances);

	// If the current fragment is within the radiusing range of a corner, the component representing that corner will
	// be 0.0 in cornerChooser. If the current fragment is outside the range of all the corners, all components will
	// be 1.0.
	float4 cornerChooser = step(float4(relativePosTL.x, relativePosTR.x, relativePosBR.x, relativePosBL.x), k_roundingRadii);
	cornerChooser *= step(float4(relativePosTL.y, relativePosTR.y, relativePosBR.y, relativePosBL.y), k_roundingRadii);

	// Invert cornerChooser and modulate each component to come up with a bool indicating whether any corner is in range
	cornerChooser = 1.0f - cornerChooser;
	float anyInRangeCheck = cornerChooser.x * cornerChooser.y * cornerChooser.z * cornerChooser.w;

	// Modulate all the corner clip values and the interior clip value to come up with the final clip value. Multiply by
	// the anyInRangeCheck in order to force full opacity if the fragment is outside the range of all the corners.
	float clipValue = (roundingVector.x * roundingVector.y * roundingVector.z * roundingVector.w) * (1.0f - anyInRangeCheck);

	// Invert clipValue so 1.0 means opaque, and 0.0 means transparent
	clipValue = 1.0f - clipValue;

	// Fade out the sample based on the results of the clipping tests
	color.a = 1.0f - ((1.0f - color.a) * clipValue);
	color.rgb *= clipValue;
#endif

	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));
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
