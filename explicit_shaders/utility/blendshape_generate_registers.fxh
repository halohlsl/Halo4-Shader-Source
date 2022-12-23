#if DX_VERSION == 9

DECLARE_PARAMETER(float4,	vs_blendshapeCompression[4],c128);
DECLARE_PARAMETER(float4,	vs_blendshapeIndices[4],	c132);
DECLARE_PARAMETER(float4,	vs_blendshapeScale[4],		c136);
DECLARE_PARAMETER(float4,	vs_blendshapeParameters,	c140);
DECLARE_PARAMETER(float4,	vs_blendshapeExportConst,	c141);

#elif DX_VERSION == 11

CBUFFER_BEGIN(BlendshapeGenerateVS)
	CBUFFER_CONST_ARRAY(BlendshapeGenerateVS,	float4,		vs_blendshapeCompression, [4],		k_vs_blendshape_generate_compression)
	CBUFFER_CONST_ARRAY(BlendshapeGenerateVS,	float4,		vs_blendshapeIndices, [4],			k_vs_blendshape_generate_indices)
	CBUFFER_CONST_ARRAY(BlendshapeGenerateVS,	float4,		vs_blendshapeScale, [4],			k_vs_blendshape_generate_scale)
	CBUFFER_CONST(BlendshapeGenerateVS,			float4,		vs_blendshapeParameters,			k_vs_blendshape_generate_parameters)
	CBUFFER_CONST(BlendshapeGenerateVS,			uint,		cs_blendshape_max_index,			k_cs_blendshape_max_index)
CBUFFER_END

RW_BYTE_ADDRESS_BUFFER(cs_blendshape_output_buffer,		k_cs_blendshape_output_buffer,		0)
BYTE_ADDRESS_BUFFER(cs_blendshape_input_buffer,			k_cs_blendshape_input_buffer,		16)

#define CS_BLENDSHAPE_GENERATE_THREADS 64

#endif
