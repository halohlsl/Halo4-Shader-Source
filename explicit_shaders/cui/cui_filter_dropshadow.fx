#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_dropshadow_color k_cui_pixel_shader_color0
#define k_dropshadow_angle k_cui_pixel_shader_scalar0
#define k_dropshadow_distance k_cui_pixel_shader_scalar1
#define k_dropshadow_spread k_cui_pixel_shader_scalar2
#define k_dropshadow_size k_cui_pixel_shader_scalar3
#define k_dropshadow_blursamplecount k_cui_pixel_shader_scalar4

float dropshadowTex2D(in texture_sampler_2d source_sampler, in float4 sampler_transform, in float2 texcoord)
{
	float4 color = sample2D(source_sampler, texcoord);

	// For the purposes of the dropshadow, we want to use non-premultiplied alpha; so for textures
	// that use premultiplied alpha, we convert to non-premultiplied form.
	return color.a * (-1 * sampler_transform.x) + (1 - sampler_transform.y);
}

float2 dropshadowBiasedTexCoord(in float2 baseTexCoord, in float4 gradients, in float2 stepOffset)
{
	return baseTexCoord + (gradients.xz * stepOffset.x) + (gradients.yw * stepOffset.y);
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Calculate the sample offset based on the angle, where Angle==0 steps to the right, Angle==90
	// steps up, and Angle==-90 steps down.
	float2 sampleOffset;
	sincos(k_dropshadow_angle, sampleOffset.y, sampleOffset.x);
	sampleOffset.y = -1 * sampleOffset.y;

	float2 texcoord = input.texcoord;

#if (! defined(pc)) || (DX_VERSION == 11)

#ifdef xenon
	float4 gradients;
	asm {
		getGradients gradients, texcoord, source_sampler0
	};
#else
	float4 gradients = GetGradients(texcoord);
#endif

	// Scale the sampleOffset so each whole number of k_dropshadow_distance represents 1 pixel in screen space.
	const float2 sampleTexCoord = texcoord + float2(
		sampleOffset.x * k_dropshadow_distance * length(gradients.xy),
		sampleOffset.y * k_dropshadow_distance * length(gradients.zw));

	// This code could be refactored to use a static loop to allow an arbitrarily large kernal size, but I think that's a bad
	// idea. In practice, I believe the kernal size should be kept to 4x4 or below for performance considerations. Furthermore,
	// if the kernal size is going to be 2x2, 3x3, or 4x4, it is more efficient to unroll the loop by hand.

	float shadowFactor = 0;
	if (k_dropshadow_blursamplecount == 4)
	{
		// Blur kernal is:
		//		[.03, .06, .06, .03]
		//		[.06, .10, .10, .06]
		//		[.06, .10, .10, .06]
		//		[.03, .06, .06, .03]

		float4 shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(      -k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-0.5 * k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0.5 * k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(       k_dropshadow_size, -k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.03, 0.06, 0.06, 0.03));

		shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(      -k_dropshadow_size, -0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-0.5 * k_dropshadow_size, -0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0.5 * k_dropshadow_size, -0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(       k_dropshadow_size, -0.5 * k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.06, 0.10, 0.10, 0.06));

		shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(      -k_dropshadow_size, 0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-0.5 * k_dropshadow_size, 0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0.5 * k_dropshadow_size, 0.5 * k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(       k_dropshadow_size, 0.5 * k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.06, 0.10, 0.10, 0.06));

		shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(      -k_dropshadow_size, k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-0.5 * k_dropshadow_size, k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0.5 * k_dropshadow_size, k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(       k_dropshadow_size, k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.03, 0.06, 0.06, 0.03));
	}
	else if (k_dropshadow_blursamplecount == 3)
	{
		// Blur kernal is:
		//		[.08, .12, .08]
		//		[.12, .20, .12]
		//		[.08, .12, .08]

		float4 shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-k_dropshadow_size, 0))));
		shadowFactor += dot(shadowSamples, float4(0.08, 0.12, 0.08, 0.12));

		shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0, 0))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( k_dropshadow_size, 0))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-k_dropshadow_size, k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( 0, k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.20, 0.12, 0.08, 0.12));

		shadowFactor += dropshadowTex2D(
			source_sampler0,
			k_cui_sampler0_transform,
			dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(k_dropshadow_size, k_dropshadow_size))) * 0.08;
	}
	else // k_dropshadow_blursamplecount <= 2
	{
		// Blur kernal is:
		//		[.25, .25]
		//		[.25, .25]

		float4 shadowSamples = float4(
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( k_dropshadow_size, -k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2(-k_dropshadow_size,  k_dropshadow_size))),
			dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, dropshadowBiasedTexCoord(sampleTexCoord, gradients, float2( k_dropshadow_size,  k_dropshadow_size))));
		shadowFactor += dot(shadowSamples, float4(0.25, 0.25, 0.25, 0.25));
	}
#else
	// Scale the sampleOffset so each whole number of k_dropshadow_distance represents 3.33% of the texture extents.
	// This value is somewhat arbitrary but it's relatively close to the Distance value in Photoshop.
	const float2 sampleTexCoord = texcoord + (sampleOffset * k_dropshadow_distance * 0.00333);

	float shadowFactor =
		dropshadowTex2D(source_sampler0, k_cui_sampler0_transform, sampleTexCoord).xxxx;
#endif

	shadowFactor = pow(shadowFactor, k_dropshadow_spread);

	// Convert the dropshadow result to premultiplied alpha
	float4 shadowColor = cui_linear_to_gamma2(k_dropshadow_color * shadowFactor);
	shadowColor.rgb *= shadowColor.a;
	shadowColor.a = 1 - shadowColor.a;

	// Get the base diffuse sample in premultiplied alpha form
	float4 sampleColor = cui_tex2D(texcoord);
	// Blend in the widget tint
	sampleColor = cui_tint(sampleColor, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));

	// Blend the dropshadow color and the tinted diffuse sample using the premultiplied-alpha equation.
	return float4((shadowColor.rgb * sampleColor.a) + sampleColor.rgb, min(shadowColor.a, sampleColor.a)) * ps_scale;
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
