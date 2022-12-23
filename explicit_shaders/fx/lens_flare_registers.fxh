#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, sourceSampler, s0);

// x is modulation factor, y is tint power, z is brightness, w unused
DECLARE_PARAMETER(float4, modulationFactor, c50);
DECLARE_PARAMETER(float4, tintColor, c51);
DECLARE_PARAMETER(float4, centerRotation, c240); // center(x,y), theta

DECLARE_PARAMETER(float4, flareScale, c241); // scale(x, y), projection scale(x, y)

DECLARE_PARAMETER(bool, mirrorReflectionAcrossFlare, b0);
DECLARE_PARAMETER(float4, flareOrigin_offsetBounds, c242);

DECLARE_PARAMETER(float4, transformedAxes, c243);

#elif DX_VERSION == 11

CBUFFER_BEGIN(LensFlareVS)
	CBUFFER_CONST(LensFlareVS,		float4, 	centerRotation,					k_vs_lens_flare_center_rotation)
	CBUFFER_CONST(LensFlareVS,		float4, 	flareScale, 					k_vs_lens_flare_flare_scale)
	CBUFFER_CONST(LensFlareVS,		float4, 	flareOrigin_offsetBounds, 		k_vs_lens_flare_flareorigin_offsetbounds)
	CBUFFER_CONST(LensFlareVS,		float4, 	transformedAxes,				k_vs_lens_flare_transformed_axes)
	CBUFFER_CONST(LensFlareVS,		bool, 		mirrorReflectionAcrossFlare, 	k_vs_lens_flare_bool_mirror_reflection_across_flare)
CBUFFER_END

CBUFFER_BEGIN(LensFlarePS)
	CBUFFER_CONST(LensFlarePS,		float4, 	modulationFactor, 				k_ps_lens_flare_modulation_factor)
	CBUFFER_CONST(LensFlarePS,		float4, 	tintColor,						k_ps_lens_flare_tint_color)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	sourceSampler, 		k_ps_lens_flare_source_sampler,		0)

#endif
