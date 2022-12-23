#if !defined(__CHEAP_PARTICLE_CORE_FXH)
#define __CHEAP_PARTICLE_CORE_FXH

#define EXCLUDE_MODEL_MATRICES

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "fx/cheap_particle_parameters.fxh"
#include "packed_vector.fxh"

#if DX_VERSION == 11
	#ifdef CHEAP_PARTICLE_CORE_VS
		#define particle_state_buffer vs_particle_state_buffer
		#define typeSampler vs_typeSampler
	#else
		#define particle_state_buffer cs_particle_state_buffer
		#define typeSampler cs_typeSampler
	#endif
#endif

#if defined(xenon) || (DX_VERSION == 11)

#define TYPE_TEXTURE_WIDTH 256
#define TYPE_TEXTURE_HEIGHT 8

#define TYPE_DATA_PHYSICS		(0.0)
#define TYPE_DATA_COLLISION		(1.0)
#define	TYPE_DATA_COLOR0		(2.0)
#define	TYPE_DATA_SIZE			(3.0)
#define	TYPE_DATA_RENDER		(4.0)

#ifdef xenon
DECLARE_PARAMETER(sampler, vs_positionAndAgeStream, vf0);
DECLARE_PARAMETER(sampler, vs_velocityAndDeltaAgeStream, vf1);
DECLARE_PARAMETER(sampler, vs_parametersStream, vf2);
#endif

float4 GetTypeData(float particleType, float typeDataIndex)
{
	float4 result;
	// since the buffer we store in is signed (for the other parameters) we offset particle type
	float2 texcoord = float2(particleType + 128.0, typeDataIndex);
#ifdef xenon	
	asm
	{
		tfetch2D	result,
					texcoord,
					vs_typeSampler,
					UnnormalizedTextureCoords = true,
					MagFilter = point,
					MinFilter = point,
					MipFilter = point,
					AnisoFilter = disabled,
					UseComputedLOD = false,
					UseRegisterGradients = false
//					OffsetX=	0.5,
//					OffsetY=	0.5
	};
#elif DX_VERSION == 11
	result = typeSampler.t.Load(int3(texcoord, 0));
#endif
	return result;
}

float4 GenerateRandom(float particleIndex, float arrayCoord, texture_sampler_2d_array randomSampler, float4 textureTransform)
{
	// Compute a random value by looking up into the noise texture based on particle coordinate:
	float3 randomTexcoord = float3(particleIndex * textureTransform.xy + textureTransform.zw, arrayCoord);
		
	float4 random;
#ifdef xenon
	asm
	{
		tfetch3D random,
				randomTexcoord,
				randomSampler,
				UnnormalizedTextureCoords = false,
				AnisoFilter = disabled,
				UseComputedLOD = false,
				UseRegisterGradients = false
	};
#elif DX_VERSION == 11
	random = randomSampler.t.SampleLevel(randomSampler.s, randomTexcoord, 0);
#endif
	return random;
}

float4 GenerateRandomInRange(float particleIndex, float arrayCoord, texture_sampler_2d_array randomSampler, float4 textureTransform, const float min, const float max)
{
	float4 result = GenerateRandom(particleIndex, arrayCoord, randomSampler, textureTransform);
	
	result.x = lerp(min, max, result.x);
	result.y = lerp(min, max, result.y);
	result.z = lerp(min, max, result.z);
	result.w = lerp(min, max, result.w);
	
	return result;
}

#if DX_VERSION == 11

float4 GenerateRandom(float particleIndex, float arrayCoord, texture_sampler_2d randomSampler, float4 textureTransform)
{
	// Compute a random value by looking up into the noise texture based on particle coordinate:
	float2 randomTexcoord = float2(particleIndex * textureTransform.xy + textureTransform.zw);
		
	float4 random;
	random = randomSampler.t.SampleLevel(randomSampler.s, randomTexcoord, 0);
	return random;
}

float4 GenerateRandomInRange(float particleIndex, float arrayCoord, texture_sampler_2d randomSampler, float4 textureTransform, const float min, const float max)
{
	float4 result = GenerateRandom(particleIndex, arrayCoord, randomSampler, textureTransform);
	
	result.x = lerp(min, max, result.x);
	result.y = lerp(min, max, result.y);
	result.z = lerp(min, max, result.z);
	result.w = lerp(min, max, result.w);
	
	return result;
}

#endif

float4 FetchPositionAndAge(float particleIndex)
{
	float4 positionAndAge;
#ifdef xenon	
	asm
	{
		vfetch_full positionAndAge, particleIndex, vs_positionAndAgeStream, DataFormat=FMT_32_32_32_32_FLOAT, Stride=4
	};
#elif DX_VERSION == 11
	positionAndAge = particle_state_buffer[particleIndex].position_age;
#endif
	return positionAndAge.xyzw;
}

float4 FetchVelocityAndDeltaAge(float particleIndex)
{
	float4 velocityAndDeltaAge;
#ifdef xenon
	asm
	{
		// endianness seems to require me to swap x/y and z/w
		vfetch_full velocityAndDeltaAge.yxwz, particleIndex, vs_velocityAndDeltaAgeStream, DataFormat=FMT_16_16_16_16_FLOAT, Stride=2
	};
#elif DX_VERSION == 11
	uint2 packed_data;
	packed_data = particle_state_buffer[particleIndex].velocity_delta_age;
	velocityAndDeltaAge = UnpackHalf4(packed_data);
#endif
	return velocityAndDeltaAge.xyzw;
}

float4 FetchParticleParameters(float particleIndex)
{
	float4 particleParameters;
#ifdef xenon
	asm
	{
		vfetch_full particleParameters, particleIndex, vs_parametersStream, DataFormat=FMT_8_8_8_8, Stride=1, NumFormat=integer, Signed=true
	};
#elif DX_VERSION == 11
	uint packed_data;
	packed_data = particle_state_buffer[particleIndex].parameters;
	particleParameters = UnpackSByte4(packed_data);
#endif
	return particleParameters.xyzw;
}

void MemexportPositionAndAge(float relativeParticleIndex, float4 positionAndAge)
{
#ifdef xenon
	const float4 k_offsetConst = { 0, 1, 0, 0 };
	asm
	{
		alloc export = 1
		mad eA, relativeParticleIndex, k_offsetConst, vs_positionAgeAddressOffset
		mov eM0, positionAndAge
	};
#elif DX_VERSION == 11
	cs_particle_state_buffer[relativeParticleIndex].position_age = positionAndAge;
#endif
}

void MemexportVelocityAndDeltaAge(float relativeParticleIndex, float4 velocityAndDeltaAge)
{
#ifdef xenon
	const float4 k_offsetConst = { 0, 1, 0, 0 };
	asm
	{
		alloc export= 1
		mad eA, relativeParticleIndex, k_offsetConst, vs_velocityAndDeltaAgeAddressOffset
		mov eM0, velocityAndDeltaAge
	};
#elif DX_VERSION == 11
	uint2 packed_data = PackHalf4(velocityAndDeltaAge);
	cs_particle_state_buffer[relativeParticleIndex].velocity_delta_age = packed_data;
#endif
}

void MemexportParticleParameters(float relativeParticleIndex, float4 particleParameters)
{
#ifdef xenon
	const float4 k_offsetConst = { 0, 1, 0, 0 };
	asm
	{
		alloc export= 1
		mad eA, relativeParticleIndex, k_offsetConst, vs_parametersAddressOffset
		mov eM0, particleParameters
	};
#elif DX_VERSION == 11
	uint packed_data = PackSByte4(particleParameters);
	cs_particle_state_buffer[relativeParticleIndex].parameters = packed_data;
#endif
}

float2 GenerateQuadPoint2D( // produces the given corner of the unit-size axis-aligned quad (in the range [0,1])
	float indexInt)
{
#if defined(xenon)
	// this compiles to 3 ALUs w/no waterfalling, (versus ~9 ALUs for the below pc version)
	return (frac(indexInt * 0.25f + float2(0.25f, 0.0f)) >= 0.5f);
#else // defined(xenon)
	float2 verts[4]=
	{
		float2( 0.0f, 0.0f ),	// 0
		float2( 1.0f, 0.0f ),	// 1
		float2( 1.0f, 1.0f ),	// 2
		float2( 0.0f, 1.0f ),	// 3
	};
	return verts[indexInt];
#endif // defined(xenon)
}

float2 GenerateRotatedQuadPoint2D(
	float indexInt,
	float2 origin,
	float2 dx)
{	
	float2 coord = GenerateQuadPoint2D(indexInt) - 0.5f;
	
	return	origin + coord.x * dx + coord.y * float2(-dx.y, dx.x);
}
#endif // defined(xenon)

#endif 	// !defined(__CHEAP_PARTICLE_CORE_FXH)