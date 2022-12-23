#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, 	ps_shadow_sampler_backward,	s0);

DECLARE_PARAMETER(float4,	ps_forge_lights[6],		c0);
DECLARE_PARAMETER(float4, 	vs_shadow_projection_forward[3], 	c242);
DECLARE_PARAMETER(float4, 	vs_shadow_projection_backward[3], 	c245);
DECLARE_PARAMETER(float4, 	vs_local_to_world_transform[3], 	c248);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ForgeLightMapVS)
	CBUFFER_CONST_ARRAY(ForgeLightMapVS,		float4, 	vs_shadow_projection_forward, [3], 		k_vs_forge_lightmap_shadow_projection_forward)
	CBUFFER_CONST_ARRAY(ForgeLightMapVS,		float4, 	vs_shadow_projection_backward, [3], 	k_vs_forge_lightmap_shadow_projection_backward)
	CBUFFER_CONST_ARRAY(ForgeLightMapVS,		float4, 	vs_local_to_world_transform, [3], 		k_vs_forge_lightmap_local_to_world_transform)
CBUFFER_END

CBUFFER_BEGIN(ForgeLightMapPS)
	CBUFFER_CONST_ARRAY(ForgeLightMapPS,		float4,		ps_forge_lights, [6],					k_ps_forge_lightmap_lights)
CBUFFER_END
	
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_shadow_sampler_backward,		k_ps_forge_lightmap_shadow_sampler_backward,		0)

#endif
