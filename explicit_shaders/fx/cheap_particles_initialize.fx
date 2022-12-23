#include "fx/cheap_particle_core.fxh"

void InitializeParticle(in int index)
{
	float particleIndex = index;

	// Fill the buffers with junk values.
	float4 positionAndAge = float4(0, 0, 0, 2); // Proper values: (NaN.xyz, -1);
	float4 velocityAndDeltaAge = float4(0, 1, 0, 0); // (NaN);
	float4 particleParameters = float4(0, 0, 0, 0); // (NaN);
	
	MemexportPositionAndAge(particleIndex, positionAndAge);
	MemexportVelocityAndDeltaAge(particleIndex, velocityAndDeltaAge);
	MemexportParticleParameters(particleIndex, particleParameters);
}

#if defined(xenon)

void DefaultVS(in int index : INDEX)
{
	InitializeParticle(index);
}

float4 DefaultPS() : SV_Target0
{
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

#elif DX_VERSION == 11

[numthreads(CS_CHEAP_PARTICLE_INIT_THREADS,1,1)]
void DefaultCS(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		InitializeParticle(index);
	}
}

#else

void DefaultVS(out float4 outPosition : SV_Position) { outPosition = 0.0f; }
float4 DefaultPS() : SV_Target0 { return 0.0f; }

#endif // !defined(xenon)

BEGIN_TECHNIQUE
{
	pass tiny_position
	{
#if DX_VERSION == 11
		SET_COMPUTE_SHADER(DefaultCS());
#else
		SET_VERTEX_SHADER(DefaultVS());
		SET_PIXEL_SHADER(DefaultPS());
#endif
	}
}