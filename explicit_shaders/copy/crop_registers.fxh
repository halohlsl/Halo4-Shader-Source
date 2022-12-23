#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_source_sampler,		s0);

DECLARE_PARAMETER(float4, ps_texcoord_xform,		c3);
DECLARE_PARAMETER(float4, ps_crop_bounds,			c4);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CropPS)
	CBUFFER_CONST(CropPS,		float4,		ps_texcoord_xform,		k_ps_crop_texcoord_xform)
	CBUFFER_CONST(CropPS,		float4,		ps_crop_bounds,			k_ps_crop_bounds)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler,		k_ps_crop_source_sampler,		0)

#endif
