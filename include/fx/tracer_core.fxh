#if !defined(__TRACER_CORE_FXH)
#define __TRACER_CORE_FXH

#define EXCLUDE_MODEL_MATRICES

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "fx/tracer_parameters.fxh"
#include "fx/tracer_types.fxh"
#include "fx/fx_functions.fxh"
#include "blend_modes.fxh"
#include "packed_vector.fxh"

// Match with the fields loaded into TracerGpu::QueueProfile.
struct TracerProfileState
{
	float3 position;
	float3 velocity;
	float rotation;
	float lifespan;
	float age;
	float4 color;
	float4 initialColor;
	float initialAlpha;
	float4 random;
	float size;
	float intensity;
	float blackPoint;
	float palette;
	float2 offset;
	float length;
	float percentile;
};

#ifdef xenon

TracerProfileState ReadTracerProfileState(int index)
{
	TracerProfileState state;
	
	// Match with TracerGpu::Layout
	// Note that because of format specifications, state fields must be carefully assigned 
	// to an appropriate sample.
	float4 posSample;
	float4 velSample;
	float4 rndSample;
	float4 miscSample4x16f;
	float4 miscSample4x16un;
	float4 miscSample2x16f;
	float4 colSample;
	float4 col2Sample;

#if !defined(pc)
	asm {
		vfetch posSample, index.x, position
		vfetch velSample, index.x, position1
		vfetch rndSample, index.x, position2
		vfetch miscSample4x16f, index.x, texcoord0
		vfetch miscSample4x16un, index.x, texcoord2
		vfetch miscSample2x16f, index.x, texcoord3
		vfetch colSample, index.x, color
		vfetch col2Sample, index.x, color1
	};
#else
	posSample = vs_hiddenFromCompilerNaN;
	velSample = vs_hiddenFromCompilerNaN;
	rndSample = vs_hiddenFromCompilerNaN;
	miscSample4x16f = vs_hiddenFromCompilerNaN;
	miscSample4x16un = vs_hiddenFromCompilerNaN;
	miscSample2x16f = vs_hiddenFromCompilerNaN;
	colSample = vs_hiddenFromCompilerNaN;
	col2Sample = vs_hiddenFromCompilerNaN;
#endif // !defined(pc)

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	state.position = posSample.xyz; // s_gpu_storage_4x32f
	state.age = posSample.w;
	state.velocity = velSample.xyz; // s_gpu_storage_4x16f --- doesn't get fetched from render
	state.initialAlpha = velSample.w;
	state.random = rndSample; // s_gpu_storage_4x16un --- doesn't get fetched from render
	state.size = miscSample4x16f.x; // s_gpu_storage_4x16f --- doesn't get fetched from update
	state.intensity = miscSample4x16f.y;
	state.offset = miscSample4x16f.zw;
	state.rotation = miscSample4x16un.x; // s_gpu_storage_4x16un --- doesn't get fetched from update
	state.blackPoint = miscSample4x16un.y;
	state.palette = miscSample4x16un.z;
	state.percentile = miscSample4x16un.w;
	state.length = miscSample2x16f.x; // s_gpu_storage_2x16f
	state.lifespan = miscSample2x16f.y;
	state.color = colSample; // s_gpu_storage_argb8 --- doesn't get fetched from update
	state.initialColor = col2Sample; // s_gpu_storage_argb8 --- doesn't get fetched from update
	
	return state;
}

TracerProfileState VSReadTracerProfileState(int index)
{
	return ReadTracerProfileState(index);
}

#elif DX_VERSION == 11

TracerProfileState UnpackTracerProfileState(in RawTracerProfileState input)
{
	float4 unpacked_velocity = UnpackHalf4(input.velocity);
	float4 unpacked_miscFloat = UnpackHalf4(input.miscFloat);
	float4 unpacked_miscInt = UnpackUShort4N(input.miscInt);
	float2 unpacked_miscFloat2 = UnpackHalf2(input.miscFloat2);

	TracerProfileState output;
	output.position = input.position.xyz;
	output.age = input.position.w;
	output.velocity = unpacked_velocity.xyz;
	output.initialAlpha = unpacked_velocity.w;
	output.random = UnpackUShort4N(input.random);
	output.size = unpacked_miscFloat.x;
	output.intensity = unpacked_miscFloat.y;
	output.offset = unpacked_miscFloat.zw;
	output.rotation = unpacked_miscInt.x;
	output.blackPoint = unpacked_miscInt.y;
	output.palette = unpacked_miscInt.z;
	output.percentile = unpacked_miscInt.w;
	output.length = unpacked_miscFloat2.x;
	output.lifespan = unpacked_miscFloat2.y;
	output.color = UnpackARGB8(input.color);
	output.initialColor = UnpackARGB8(input.initialColor);
	return output;
}

RawTracerProfileState PackTracerProfileState(in TracerProfileState input)
{
	RawTracerProfileState output;
	output.position = float4(input.position, input.age);
	output.velocity = PackHalf4(float4(input.velocity, input.initialAlpha));
	output.random = PackUShort4N(input.random);
	output.miscFloat = PackHalf4(float4(input.size, input. intensity, input.offset));
	output.miscInt = PackUShort4N(float4(input.rotation, input.blackPoint, input.palette, input.percentile));
	output.miscFloat2 = PackHalf2(float2(input.length, input.lifespan));
	output.color = PackARGB8(input.color);
	output.initialColor = PackARGB8(input.initialColor);
	output.padding = 0;

	return output;
}

TracerProfileState ReadTracerProfileState(int index)
{
	return UnpackTracerProfileState(cs_tracer_profile_state_buffer[index]);
}

TracerProfileState VSReadTracerProfileState(int index)
{
	return UnpackTracerProfileState(vs_tracer_profile_state_buffer[index]);
}

#endif

#endif 	// !defined(__TRACER_CORE_FXH)