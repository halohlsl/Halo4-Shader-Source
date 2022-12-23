#if !defined(__TRACER_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __TRACER_PARAMETERS_FXH

#include "fx_parameters.fxh"
#endif

#define k_profilesPerRow 16
#define k_maxRowsPerStrip 8

// Match with TracerStates::InputEnum
// enum TracerState
#define eTS_profileAge 0 // eIE_profileAge
#define eTS_profilePercentile 1 // eTS_profilePercentile
#define eTS_unused 2 // eTS_unused
#define eTS_profileRandom 3 // eTS_profileRandom
#define eTS_profileCorrelation1	4 // eTS_profileCorrelation1,
#define eTS_profileCorrelation2	5 // eTS_profileCorrelation2,
#define eTS_profileCorrelation3 6 // eTS_profileCorrelation3,
#define eTS_profileCorrelation4 7 // eTS_profileCorrelation4,
#define eTS_gameTime 8 // eTS_gameTime,
#define eTS_tracerRandom 9 // eTS_tracerRandom,
#define eTS_tracerCorrelation1 10 // eTS_tracerCorrelation1,
#define eTS_tracerCorrelation2 11 // eTS_tracerCorrelation2,
#define eTS_locationSpeed 12 // eTS_locationSpeed,
#define eTS_tracerLength 13 // eTS_tracerLength,
#define eTS_systemAge 14 // eTS_systemAge,
#define eTS_systemLod 15 // eTS_systemLod,
#define eTS_effectAScale 16 // eTS_effectAScale,
#define eTS_effectBScale 17 // eTS_effectBScale,
#define eTS_invalid 18 // eTS_invalid,
#define eTS_count 19 // eIE_count,

#ifndef TRACER_STRUCTS_DEFINED
#define TRACER_STRUCTS_DEFINED

// Match with OverallState in TracerGpu::SetMaterialState()
struct SingleState
{
	PADDED(float,1,value)
};
struct TracerFade
{
	float4 _originRange_originCutoff_edgeRange_edgeCutoff;
#ifndef DEFINE_CPP_CONSTANTS	
	#define originRange _originRange_originCutoff_edgeRange_edgeCutoff.x
	#define originCutoff _originRange_originCutoff_edgeRange_edgeCutoff.y
	#define edgeRange _originRange_originCutoff_edgeRange_edgeCutoff.z
	#define edgeCutoff _originRange_originCutoff_edgeRange_edgeCutoff.w
#endif
};
struct TracerOverallState
{
	PADDED(float,1,profileShape)
	PADDED(float,1,ngonSides)
	PADDED(float,1,appearanceFlags)
	PADDED(float,1,numProfiles)
	PADDED(float,1,percentileStep)
	PADDED(float,1,cappedLength)
	PADDED(float,1,offset)
	PADDED(float,4,localSpaceOffset_gameTime)
	PADDED(float,2,uvTilingRate)
	PADDED(float,2,uvScrollRate)
	PADDED(float,2,uvOffset)
	PADDED(float,3,origin)
	PADDED(float,3,direction)
	TracerFade fade;
	SingleState inputs[eTS_count];
};

// Match with Strip in TracerGpu::SetMaterialStrip()
struct TracerStrip
{
	PADDED_ARRAY(float,1,row,[k_maxRowsPerStrip])
};

#if DX_VERSION == 11

struct RawTracerProfileState
{
	float4 position;
	uint2 velocity;
	uint2 random;
	uint2 miscFloat;
	uint2 miscInt;
	uint miscFloat2;
	uint color;
	uint initialColor;
	uint padding;
};

#endif

#endif

#if DX_VERSION == 9

DECLARE_PARAMETER(TracerOverallState, vs_tracerOverallState, c40); // 32 variables
DECLARE_PARAMETER(TracerStrip, vs_tracerStrip, c72); // 8 variables

#elif DX_VERSION == 11

CBUFFER_BEGIN(TracerVS)
	CBUFFER_CONST(TracerVS,		TracerOverallState, 	vs_tracerOverallState, 		k_vs_tracer_overall_state)
	CBUFFER_CONST(TracerVS,		TracerStrip, 			vs_tracerStrip, 			k_vs_tracer_strip)
CBUFFER_END

CBUFFER_BEGIN(TracerCS)
	CBUFFER_CONST(TracerCS,		uint2,					cs_tracer_index_range,		k_vs_tracer_index_range)
CBUFFER_END

STRUCTURED_BUFFER(cs_tracer_address_buffer,					k_cs_tracer_address_buffer,					uint,					4)
STRUCTURED_BUFFER(cs_tracer_profile_state_spawn_buffer,		k_cs_tracer_profile_state_spawn_buffer,		RawTracerProfileState,	5)

RW_STRUCTURED_BUFFER(cs_tracer_profile_state_buffer,		k_cs_tracer_profile_state_buffer,			RawTracerProfileState,	0)

STRUCTURED_BUFFER(vs_tracer_profile_state_buffer,			k_vs_tracer_profile_state_buffer,			RawTracerProfileState,	16)

#endif

#ifdef DEFINE_CPP_CONSTANTS
#undef k_profilesPerRow
#undef k_maxRowsPerStrip
#endif

#endif 	// !defined(__TRACER_PARAMETERS_FXH)