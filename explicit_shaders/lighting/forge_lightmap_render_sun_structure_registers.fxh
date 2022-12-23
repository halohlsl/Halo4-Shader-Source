#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, 	vs_positionSampler, 		s0);
DECLARE_PARAMETER(sampler, 	vs_shadowSampler, 		s1);

DECLARE_PARAMETER(float4, 	vs_mem_export_stream_constant,	c239);
DECLARE_PARAMETER(bool, 	vs_overwrite, b0);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ForgeLightmapRenderSunStructureVS)
	CBUFFER_CONST(ForgeLightmapRenderSunStructureVS,		float4,			vs_screen_scale_offset,				k_vs_forge_lightmap_screen_scale_offset)
	CBUFFER_CONST(ForgeLightmapRenderSunStructureVS,		bool,			vs_overwrite,						k_vs_forge_lightmap_render_sun_structure_bool_overwrite)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D_ARRAY,	vs_positionSampler, 	k_vs_forge_lightmap_render_sun_structure_position_sampler,		0)
VERTEX_TEXTURE_AND_SAMPLER(_2D_ARRAY,	vs_shadowSampler, 		k_vs_forge_lightmap_render_sun_structure_shadow_sampler,		1)

#endif
