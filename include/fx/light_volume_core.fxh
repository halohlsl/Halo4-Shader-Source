#if !defined(__LIGHT_VOLUME_CORE_FXH)
#define __LIGHT_VOLUME_CORE_FXH

#define EXCLUDE_MODEL_MATRICES

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "fx/light_volume_parameters.fxh"
#include "fx/light_volume_types.fxh"
#include "fx/fx_functions.fxh"
#include "blend_modes.fxh"
#if DX_VERSION == 11
#include "packed_vector.fxh"
#endif

// Match with the fields of c_light_volume_gpu::s_layout.
struct ProfileMemexportedState
{
	float3 position;
	float percentile;
	float4 color;
	float thickness;
	float intensity;
};

// Take the index from the vertex input semantic and translate it into the actual lookup 
// index in the vertex buffer.
int ProfileIndexToBufferIndex(int profileIndex)
{
	// ###ctchou $TODO FUCKED BY NEW XDK COMPILER -- TURNING OFF OPTIMIZATIONS
	[noExpressionOptimizations]

	int lightVolumeRow = round(profileIndex / k_profilesPerRow);
	int profileIndexWithinRow = round(profileIndex % k_profilesPerRow);
	int bufferRow = vs_lightVolumeStrip.row[lightVolumeRow];
	
	return bufferRow * k_profilesPerRow + profileIndexWithinRow;
}

#ifdef xenon

ProfileMemexportedState ReadProfileMemexportedState(int index)
{
	ProfileMemexportedState state;
	
	// Match with c_light_volume_gpu::e_state, and with c_light_volume_gpu::queue_profile().
	// Note that because of format specifications, state fields must be carefully assigned 
	// to an appropriate sample.
	float4 posSample; // s_gpu_storage_4x32f
	float4 miscSample2x16f;
	float4 colSample; // s_gpu_storage_argb8

#if !defined(pc)
	asm {
		vfetch posSample, index.x, position
		vfetch miscSample2x16f, index.x, texcoord0
		vfetch colSample, index.x, color
	};
#else
	posSample = vs_hiddenFromCompilerNaN;
	miscSample2x16f = vs_hiddenFromCompilerNaN;
	colSample = vs_hiddenFromCompilerNaN;
#endif // !defined(pc)

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	state.position = posSample.xyz; 
	state.percentile = posSample.w;
	state.thickness = miscSample2x16f.x;
	state.intensity = miscSample2x16f.y;
	state.color = colSample;
	
	return state;
}

#elif DX_VERSION == 11

#ifdef LIGHT_VOLUME_CORE_CS
#define light_volume_state_buffer cs_light_volume_state_buffer
#else
#define light_volume_state_buffer vs_light_volume_state_buffer
#endif

ProfileMemexportedState ReadProfileMemexportedState(in int index)
{
	ProfileMemexportedState state;
	
	float4 posSample = light_volume_state_buffer[index].pos;
	float2 miscSample = UnpackHalf2(light_volume_state_buffer[index].misc);
	float4 colSample = UnpackARGB8(light_volume_state_buffer[index].col);
	
	state.position = posSample.xyz;
	state.percentile = posSample.w;
	state.thickness = miscSample.x;
	state.intensity = miscSample.y;
	state.color = colSample;
	
	return state;
}

#ifdef LIGHT_VOLUME_CORE_CS
void WriteProfileMemexportedState(in ProfileMemexportedState state, in int index)
{
	light_volume_state_buffer[index].pos = float4(state.position, state.percentile);
	light_volume_state_buffer[index].misc = PackHalf2(float2(state.thickness, state.intensity));
	light_volume_state_buffer[index].col = PackARGB8(state.color);
	light_volume_state_buffer[index].pad = 0;
}
#endif

#endif

#endif 	// !defined(__LIGHT_VOLUME_CORE_FXH)