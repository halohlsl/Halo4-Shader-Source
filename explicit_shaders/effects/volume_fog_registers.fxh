#if DX_VERSION == 9

DECLARE_PARAMETER(float4,		vs_projectionScaleOffset, 		c10);
sampler2D fog_volume_sampler : register(s0);
sampler2D depth_sampler : register(s0);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VolumeFogVS)
	CBUFFER_CONST(VolumeFogVS,		float4,		vs_projectionScaleOffset,		k_vs_volume_fog_projection_scale_offset)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	fog_volume_sampler,		k_ps_volume_fog_volume_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,			k_ps_volume_fog_depth_sampler,		0)

#endif
