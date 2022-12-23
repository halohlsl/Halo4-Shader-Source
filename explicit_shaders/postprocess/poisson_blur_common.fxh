#include "poisson_blur_registers.fxh"

float4 PoissonBlur(
	const texture_sampler_2d sourceSampler,
	const in float2 texcoord,
	const in float blurIntensity,
	in float4 color,
	uniform int numPoissonTaps)
{
	float2 blurTapScale = (ps_scale.xy * blurIntensity + ps_scale.zw) * ps_pixel_size.xy;

	[loop]
	for (int curPoissonTap = 0; curPoissonTap < numPoissonTaps; ++curPoissonTap)
	{
		color += sample2DLOD(sourceSampler, texcoord + externalPoissonKernel[curPoissonTap].xy * blurTapScale.xy, 0, false);
	}

	return color / (numPoissonTaps + 1);
}
