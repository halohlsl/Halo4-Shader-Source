#if !defined(__LIGHT_VOLUME_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __LIGHT_VOLUME_PARAMETERS_FXH
#endif

#include "fx_parameters.fxh"

#define k_profilesPerRow 16
#define k_maxRowsPerStrip 8

// Match with c_light_volume_state::InputEnum
// enum LightVolumeState
#define eLVS_profilePercentile 0 // _profile_percentile
#define eLVS_gameTime 1 // _game_time
#define eLVS_systemAge 2 // _system_age
#define eLVS_lightVolumeRandom 3 // _light_volume_random
#define eLVS_lightVolumeCorrelation1	4 // _light_volume_correlation_1,
#define eLVS_lightVolumeCorrelation2	5 // _light_volume_correlation_2,
#define eLVS_systemLOD 6 // _system_lod,
#define eLVS_effectAScale 7 // _effect_a_scale,
#define eLVS_effectBScale 8 // _effect_b_scale,
#define eLVS_invalid 9 // _invalid,
#define eLVS_count 10 // k_total_count,

#ifndef LIGHT_VOLUME_STRUCTS_DEFINED
#define LIGHT_VOLUME_STRUCTS_DEFINED
// Match with OverallState in c_light_volume_gpu::SetMaterialState()
struct SingleState
{
	PADDED(float,1,value)
};

struct LightVolumeOverallState
{
	PADDED(float,1,appearanceFlags)
	PADDED(float,1,brightnessRatio)
	PADDED(float,1,offset)
	PADDED(float,1,numProfiles)
	PADDED(float,1,profileDistance)
	PADDED(float,1,profileLength)
	PADDED(float,3,origin)
	PADDED(float,3,direction)
	SingleState inputs[eLVS_count];
};

// Match with Strip in c_light_volume_gpu::set_material_strip()
struct LightVolumeStrip
{
	PADDED_ARRAY(float,1,row,[k_maxRowsPerStrip])
};
#endif

#if DX_VERSION == 9

///////////////////////////////////////////
// vertex shader light volume parameters
DECLARE_PARAMETER(LightVolumeOverallState, vs_lightVolumeOverallState, c40); // 18 variables
DECLARE_PARAMETER(LightVolumeStrip, vs_lightVolumeStrip, c60); // 8 variables

#elif DX_VERSION == 11

#define CS_LIGHT_VOLUME_UPDATE_THREADS 64

#ifndef DEFINED_LIGHT_VOLUME_STRUCTS
#define DEFINED_LIGHT_VOLUME_STRUCTS
struct RawProfileState
{
	float4 pos;
	uint misc;
	uint col;
	uint2 pad;
};
#endif

CBUFFER_BEGIN(LightVolumeVS)
	CBUFFER_CONST(LightVolumeVS,			LightVolumeOverallState, 	vs_lightVolumeOverallState, 	k_vs_light_volume_overall_state)
	CBUFFER_CONST(LightVolumeVS,			LightVolumeStrip, 			vs_lightVolumeStrip, 			k_vs_light_volume_strip)
CBUFFER_END

CBUFFER_BEGIN(LightVolumeIndexRange)
	CBUFFER_CONST(LightVolumeIndexRange,	uint2,						light_volume_index_range,		k_light_volume_index_range)
CBUFFER_END

RW_STRUCTURED_BUFFER(cs_light_volume_state_buffer,	k_cs_light_volume_state_buffer,		RawProfileState, 	0)
STRUCTURED_BUFFER(vs_light_volume_state_buffer,		k_vs_light_volume_state_buffer,		RawProfileState,	16)

#endif

#ifdef DEFINE_CPP_CONSTANTS
#undef k_profilesPerRow
#undef k_maxRowsPerStrip
#endif

#endif 	// !defined(__LIGHT_VOLUME_PARAMETERS_FXH)
