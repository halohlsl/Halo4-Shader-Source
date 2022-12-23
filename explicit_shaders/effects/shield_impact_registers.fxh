/*
SHIELD_IMPACT_REGISTERS.FX
Copyright (c); Microsoft Corporation, 2007. all rights reserved.
4/05/2007 9:15:00 AM (kuttas);

*/

#if DX_VERSION == 9

// ensure that these don't conflict with oneshot/persist registers

DECLARE_PARAMETER(float4, vertex_params,		c80);
DECLARE_PARAMETER(float4, vertex_params2, 		c81);
DECLARE_PARAMETER(float4, impact0_params, 		c8);
DECLARE_PARAMETER(float4, impact1_params, 		c9);

DECLARE_PARAMETER(float4, impact0_color,		c108);			// used -- dynamic
DECLARE_PARAMETER(float4, impact1_color,		c109);			// unused

DECLARE_PARAMETER(float4, plasma_offsets,		c112);			// used -- dynamic: linear with time
DECLARE_PARAMETER(float4, edge_glow,			c113);			// used -- dynamic: user function
DECLARE_PARAMETER(float4, plasma_color,			c114);			// used -- dynamic: user function
DECLARE_PARAMETER(float4, plasma_edge_color,	c115);			// used -- dynamic: user function (actually the delta between plasma_color and plasma_edge_color);

DECLARE_PARAMETER(float4, edge_scales,			c116);			// used -- static
DECLARE_PARAMETER(float4, edge_offsets,			c117);			// used -- static
DECLARE_PARAMETER(float4, plasma_scales,		c118);			// used -- static
DECLARE_PARAMETER(float4, depth_fade_params,	c119);			// used -- static

DECLARE_PARAMETER(float4, depth_constants,		c120);

// noise textures
DECLARE_PARAMETER(sampler, shield_impact_noise_texture1, s0);
DECLARE_PARAMETER(sampler, shield_impact_noise_texture2, s1);
DECLARE_PARAMETER(sampler, hitBlobTexture, s2);
DECLARE_PARAMETER(sampler, vs_shield_impact_noise_texture1, s0);
DECLARE_PARAMETER(sampler, vs_shield_impact_noise_texture2, s1);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShieldImpactVS)
	CBUFFER_CONST(ShieldImpactVS,		float4, 	vertex_params,			k_vs_shield_impact_vertex_params)
	CBUFFER_CONST(ShieldImpactVS,		float4, 	vertex_params2, 		k_vs_shield_impact_vertex_params2)
	CBUFFER_CONST(ShieldImpactVS,		float4, 	impact0_params, 		k_vs_shield_impact_impact0_params)
	CBUFFER_CONST(ShieldImpactVS,		float4, 	impact1_params, 		k_vs_shield_impact_impact1_params)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D,	vs_shield_impact_noise_texture1, 	k_vs_shield_impact_sampler_impact_noise_texture1,	 		0)
VERTEX_TEXTURE_AND_SAMPLER(_2D,	vs_shield_impact_noise_texture2, 	k_vs_shield_impact_sampler_impact_noise_texture2,		 	1)
	
CBUFFER_BEGIN(ShieldImpactPS)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	impact0_color,			k_ps_shield_impact_impact0_color)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	impact1_color,		    k_ps_shield_impact_impact1_color)		
	CBUFFER_CONST(ShieldImpactPS,			float4, 	plasma_offsets,		    k_ps_shield_impact_plasma_offsets)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	edge_glow,			    k_ps_shield_impact_edge_glow)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	plasma_color,		    k_ps_shield_impact_plasma_color)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	plasma_edge_color,	    k_ps_shield_impact_plasma_edge_color)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	edge_scales,		    k_ps_shield_impact_edge_scales)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	edge_offsets,		    k_ps_shield_impact_edge_offsets)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	plasma_scales,		    k_ps_shield_impact_plasma_scales)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	depth_fade_params,	    k_ps_shield_impact_depth_fade_params)
	CBUFFER_CONST(ShieldImpactPS,			float4, 	depth_constants,	    k_ps_shield_impact_depth_constants)
CBUFFER_END
	
PIXEL_TEXTURE_AND_SAMPLER(_2D,	shield_impact_noise_texture1, 		k_ps_shield_impact_sampler_impact_noise_texture1,	 0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	shield_impact_noise_texture2, 		k_ps_shield_impact_sampler_impact_noise_texture2,	 1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	hitBlobTexture, 					k_ps_shield_impact_sampler_hit_blob_texture,		 2)
	
#endif