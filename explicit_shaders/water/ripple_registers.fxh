#ifndef RIPPLE_STRUCTS_DEFINED
#define RIPPLE_STRUCTS_DEFINED

struct s_ripple
{
	// pos_flow : position0
	float2 position;
	float2 flow;

	// life_height : texcoord0
	float life;	
	float duration;
	float rise_period;	
	float height;

	// shock_spread : texcoord1
	float2 shock;	
	float size;	
	float spread;

	// pendulum : texcoord2
	float pendulum_phase;
	float pendulum_revolution;
	float pendulum_repeat;

	// pattern : texcoord3
	float pattern_start_index;
	float pattern_end_index;

	// foam : texcoord4
	float foam_out_radius;
	float foam_fade_distance;
	float foam_life;
	float foam_duration;	

	// flags : color0
	bool flag_drift;	
	bool flag_pendulum;
	bool flag_foam;
	bool flag_foam_game_unit;

	// funcs : color1
	int func_rise;
	int func_descend;
	int func_pattern;
	int func_foam;	
};

#endif

CBUFFER_BEGIN(WaterRippleVS)
	CBUFFER_CONST(WaterRippleVS,		float4,			k_vs_ripple_memexport_addr,					k_vs_water_ripple_memexport_addr)
	CBUFFER_CONST(WaterRippleVS,		float,			k_vs_ripple_pattern_count,					k_vs_water_ripple_pattern_count)
	CBUFFER_CONST(WaterRippleVS,		float3,			k_vs_ripple_pattern_count_pad,				k_vs_water_ripple_pattern_count_pad)
	CBUFFER_CONST(WaterRippleVS,		float4,			hidden_from_compiler,						k_vs_water_ripple_hidden_from_compiler)
	CBUFFER_CONST(WaterRippleVS,		float,			k_vs_ripple_real_frametime_ratio,			k_vs_water_ripple_real_frametime_ratio)
	CBUFFER_CONST(WaterRippleVS,		float3,			k_vs_ripple_real_frametime_ratio_pad,		k_vs_water_ripple_real_frametime_ratio_pad)
	CBUFFER_CONST(WaterRippleVS,		float,			k_vs_ripple_particle_index_start,			k_vs_water_ripple_particle_index_start)
	CBUFFER_CONST(WaterRippleVS,		float3,			k_vs_ripple_particle_index_start_pad,		k_vs_water_ripple_particle_index_start_pad)
	CBUFFER_CONST(WaterRippleVS,		float,			k_vs_maximum_ripple_particle_number,		k_vs_water_ripple_maximum_ripple_particle_number)
	CBUFFER_CONST(WaterRippleVS,		float3,			k_vs_maximum_ripple_particle_number_pad,	k_vs_water_ripple_maximum_ripple_particle_number_pad)
	CBUFFER_CONST(WaterRippleVS,		float3,			k_vs_camera_position,						k_vs_water_ripple_camera_position)
	CBUFFER_CONST(WaterRippleVS,		float,			k_vs_camera_position_pad,					k_vs_water_ripple_camera_position_pad)
CBUFFER_END

CBUFFER_BEGIN(WaterRipplePS)
	CBUFFER_CONST(WaterRipplePS,		float4,			k_ps_camera_position,						k_ps_water_ripple_camera_position)
	CBUFFER_CONST(WaterRipplePS,		float,			k_ps_underwater_murkiness,					k_ps_water_ripple_underwater_murkiness)
	CBUFFER_CONST(WaterRipplePS,		float3,			k_ps_underwater_fog_color,					k_ps_water_ripple_underwater_fog_color)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D_ARRAY,	tex_ripple_pattern,			k_ps_water_ripple_pattern,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,			tex_ripple_buffer_height, 	k_ps_water_ripple_buffer_height,	1)

CBUFFER_BEGIN(WaterRippleIndex)
	CBUFFER_CONST(WaterRippleIndex,			uint2,		ripple_index_range,							k_ripple_index_range)
CBUFFER_END

#define CS_RIPPLE_UPDATE_THREADS 64

RW_STRUCTURED_BUFFER(cs_ripple_buffer,		k_cs_ripple_buffer,		s_ripple,		0)
STRUCTURED_BUFFER(vs_ripple_buffer,			k_vs_ripple_buffer,		s_ripple,		16)
