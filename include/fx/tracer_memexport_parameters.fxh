#if !defined(__TRACER_MEMEXPORT_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __TRACER_MEMEXPORT_PARAMETERS_FXH

#include "fx_parameters.fxh"
#else
#include "bonobo_function_types.fxh"
#endif

// Match with MULTI_INCLUDE_USAGE_GPU in TracerProperties.h!  Supar important!
// enum TracerProperty
#define eTP_profileSelfAcceleration 0
#define eTP_profileSize 1
#define eTP_profileOffset 2
#define eTP_profileRotation 3
#define eTP_profileColor 4
#define eTP_profileAlpha 5
#define eTP_profileAlpha2 6
#define eTP_profileBlackPoint 7
#define eTP_profilePalette 8
#define eTP_profileIntensity 9
#define eTP_count 10

// Match with TracerGpu::StateEnum.
// enum MemexportState
#define eMS_pos 0
#define eMS_vel 1
#define	eMS_rnd 2
#define eMS_misc4x16f 3
#define eMS_misc4x16un 4
#define eMS_misc2x16f 5
#define eMS_col 6
#define eMS_col2 7
#define eMS_count 8

#ifndef DEFINED_TRACER_MEMEXPORT_STRUCTS
#define DEFINED_TRACER_MEMEXPORT_STRUCTS

// Match with c_editable_property_base.  
// The Property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.
struct GpuProperty 
{
	float4 innards;
};
typedef GpuProperty GpuProperties[eTP_count];

// Match with s_memexport in s_gpu_layout<t_num_states>::set_memexport()
struct MemexportProperty
{
	PADDED(float,4,streamConstant)
	PADDED(float,2,strideOffset)
};
typedef MemexportProperty MemexportProperties[eMS_count];

typedef s_function_definition FunctionDefinitions[_maximum_overall_function_count];
typedef float4 FunctionColors[_maximum_overall_color_count];

#endif

#if DX_VERSION == 9

DECLARE_PARAMETER(GpuProperties, vs_gpuProperties, c81); // 10 variables
DECLARE_PARAMETER(MemexportProperties, vs_memexportProperties, c92); // 16 variables
DECLARE_PARAMETER(FunctionDefinitions, g_all_functions, c108); // 100 variables
DECLARE_PARAMETER(FunctionColors, g_all_colors, c208); // 8 variables
DECLARE_PARAMETER(float, vs_deltaTime, c216);

#elif DX_VERSION == 11

#define CS_TRACER_SPAWN_THREADS 64
#define CS_TRACER_UPDATE_THREADS 64

CBUFFER_BEGIN_FIXED(TracerMemExport, 13)
	CBUFFER_CONST(TracerMemExport,			GpuProperties, 			vs_gpuProperties, 			_k_vs_tracer_memexport_gpu_properties)
	CBUFFER_CONST(TracerMemExport,			FunctionDefinitions, 	g_all_functions, 			_k_vs_tracer_memexport_all_functions)
	CBUFFER_CONST(TracerMemExport,			FunctionColors, 		g_all_colors, 				_k_vs_tracer_memexport_all_colors)
CBUFFER_END

CBUFFER_BEGIN(TracerUpdate)
	CBUFFER_CONST(TracerUpdate,				float, 					vs_deltaTime, 				k_vs_tracer_update_delta_time)
CBUFFER_END

#endif

#endif 	// !defined(__TRACER_MEMEXPORT_PARAMETERS_FXH)
