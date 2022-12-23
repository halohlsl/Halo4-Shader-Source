#if DX_VERSION == 9

float4 externalPoissonKernel[12] : register(c32);
float4 dofDistance : register(c28);
float4 dofDistanceVS : register(c28);

#elif DX_VERSION == 11

CBUFFER_BEGIN(PoissonBlurVS)
	CBUFFER_CONST(PoissonBlurVS,			float4,		dofDistanceVS,						k_vs_poisson_blur_dof_distance)
CBUFFER_END

CBUFFER_BEGIN(PoissonBlurPS)
	CBUFFER_CONST_ARRAY(PoissonBlurPS,	float4,		externalPoissonKernel, [12],		k_ps_poisson_blur_kernel)
	CBUFFER_CONST(PoissonBlurPS,			float4,		dofDistance,						k_ps_poisson_blur_dof_distance)
CBUFFER_END

#endif