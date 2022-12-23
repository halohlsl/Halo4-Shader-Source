#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "blendshape_generate_registers.fxh"
#if DX_VERSION == 11
#include "packed_vector.fxh"
#endif

#define blendshapeMaxPerPass 16

#if defined(xenon)

DECLARE_PARAMETER(sampler,	vs_blendshapeStream,		vf4);
static const float4 vs_blendshapeOffsetConst = { 0, 1, 0, 0 };

#endif


void ApplyBlendshape(
	in float4 inPosition,
	in float4 inNormal,
	in int vertexIndex,
	out float4 position,
	out float4 normal)
{
#if defined(xenon) || (DX_VERSION== 11)

	position = inPosition;
	normal = inNormal;

	// The first pass zeroes out accumulated tension, but later passes accumulate on it
	position.w *= vs_blendshapeParameters.y;
	normal.w *= vs_blendshapeParameters.y;

	for (float i = 0; i < vs_blendshapeParameters.x && i < blendshapeMaxPerPass; ++i)
	{
		const float vIndex = vertexIndex + vs_blendshapeIndices[i/4][i%4];
		float4 blendshapePositionTension;
		float4 blendshapeNormalStretch;
#ifdef xenon		
		asm
		{
			vfetch_full blendshapePositionTension.yxwz, vIndex, vs_blendshapeStream, DataFormat=FMT_16_16_16_16, Stride=4, PrefetchCount=4, RoundIndex=true
			vfetch_mini blendshapeNormalStretch.yxwz, 								 DataFormat=FMT_16_16_16_16, Offset=2
		};
#elif DX_VERSION == 11
		uint offset = uint(vIndex) * 16;
		uint4 raw_data = cs_blendshape_input_buffer.Load4(offset);
		blendshapePositionTension = UnpackUShort4N(raw_data.xy);
		blendshapeNormalStretch = UnpackUShort4N(raw_data.zw);
#endif

		const float blendshapeScale = vs_blendshapeScale[i/4][i%4];

		// Expand the compressed range and scale the value
		blendshapePositionTension = blendshapeScale * (blendshapePositionTension * vs_blendshapeCompression[0] + vs_blendshapeCompression[1]);
		blendshapeNormalStretch   = blendshapeScale * (blendshapeNormalStretch   * vs_blendshapeCompression[2] + vs_blendshapeCompression[3]);

		// Accumulate the offsets
		position += blendshapePositionTension;
		normal	 += blendshapeNormalStretch;
	}

#else

	// output the unmodified inputs on PC
	position = inPosition;
	normal = inNormal;

#endif
}


#if DX_VERSION == 9

void ExportBlendshapeData(
	in int vertexIndex,
	in float4 outputPosition,
	in float4 outputNormal)
{
#if defined(xenon)
	// export the packed data
	int outputIndex = vertexIndex * 2;
	asm
	{
		alloc export = 2
		mad eA, outputIndex, vs_blendshapeOffsetConst, vs_blendshapeExportConst
		mov eM0, outputPosition
		mov eM1, outputNormal
	};
#endif
}

#if defined(xenon)

#define BUILD_BLENDSHAPE_VS(vertex_type)										\
void blendshape_##vertex_type##_vs(												\
	in s_##vertex_type##_vertex input,											\
	in uint vertexIndex : SV_VertexID)													\
{																				\
	float4 outPosition = 0;														\
	float4 outNormal = 0;														\
	ApplyBlendshape(input.position.xyzw, input.normal.xyzw, vertexIndex, outPosition, outNormal);\
	ExportBlendshapeData(vertexIndex, outPosition, outNormal);\
}

#else

#define BUILD_BLENDSHAPE_VS(vertex_type)										\
float4 blendshape_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	in uint vertexIndex : SV_VertexID) : SV_Position									\
{																				\
	return 0;																	\
}

#endif

// Build vertex shaders for exporting blendshape values
BUILD_BLENDSHAPE_VS(blendshape_rigid);						// base_blendshape_rigid_vs
BUILD_BLENDSHAPE_VS(blendshape_skinned);					// base_blendshape_skinned_vs

#define MAKE_PASS(entrypoint_name, vertextype_name)\
	pass vertextype_name\
	{\
		SET_VERTEX_SHADER(entrypoint_name##_##vertextype_name##_vs());\
	}

BEGIN_TECHNIQUE _default
{
	MAKE_PASS(blendshape, blendshape_rigid)
	MAKE_PASS(blendshape, blendshape_skinned)
}

#elif DX_VERSION == 11

[numthreads(CS_BLENDSHAPE_GENERATE_THREADS,1,1)]
void blendshape_generate_cs(in uint index : SV_DispatchThreadID, uniform bool accumulate)
{
	if (index < cs_blendshape_max_index)
	{
		uint offset = index * 16;
		
		float4 outPosition = 0;
		float4 outNormal = 0;
		
		float4 inPosition;
		float4 inNormal;
		if (accumulate)
		{
			uint4 raw_data = cs_blendshape_output_buffer.Load4(offset);
			inPosition = UnpackHalf4(raw_data.xy);
			inNormal = UnpackHalf4(raw_data.zw);
		} else
		{
			inPosition = float4(0,0,0,1);
			inNormal = float4(0,0,0,1);
		}
		
		ApplyBlendshape(
			inPosition,
			inNormal,
			index,
			outPosition,
			outNormal);
		
		cs_blendshape_output_buffer.Store4(offset, uint4(PackHalf4(outPosition), PackHalf4(outNormal)));
	}
}

BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_COMPUTE_SHADER(blendshape_generate_cs(false));
	}
}

BEGIN_TECHNIQUE albedo
{
	pass tiny_position
	{
		SET_COMPUTE_SHADER(blendshape_generate_cs(true));
	}
}

#endif
