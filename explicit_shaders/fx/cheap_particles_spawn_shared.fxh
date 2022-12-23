#define VERTICES_PER_PARTICLE	4
#define PARTICLE_TEXTURE_SIZE	128

#if DX_VERSION == 11
	#define randomSampler cs_randomSampler
#else
	#define randomSampler vs_randomSampler
#endif

void SpawnParticle(in int index)
{
	float particleIndex = index + vs_spawnOffset.x;
	
	float3 position;
	float3 velocity;
		
	float4 random = GenerateRandom(particleIndex, 0.5f, randomSampler, vs_randomSamplerTransform);
	
	GetPositionAndVelocity(particleIndex, random, position, velocity);
	
	float deltaAge = random.z * vs_spawnTimeParameters.w + vs_spawnTimeParameters.z;

	float4 positionAndAge = float4(position,	0.0f);
	float4 velocityAndDeltaAge = float4(velocity, deltaAge);

	float particleType = dot((random.w >= vs_spawnTypeThresholds), vs_spawnTypeConstants);
	
	float4 physics = GetTypeData(particleType, TYPE_DATA_PHYSICS);
	float drag = physics.x;
	float gravity = -physics.y;
	float turbulence = physics.z;
	float collisionRange = physics.w; // 0.1f world units

	// apply subframe time offset -- do update but without collisions
	{
		float subframeTimeOffset = vs_spawnTimeParameters.x + vs_spawnTimeParameters.y * random.z;	
		float subframeDeltaTime = subframeTimeOffset * vs_deltaTime.x;

		positionAndAge.xyz += velocityAndDeltaAge.xyz * subframeDeltaTime + float3(0, 0, gravity) * subframeDeltaTime * subframeDeltaTime;
		velocityAndDeltaAge.z += gravity * subframeDeltaTime;	
		
		positionAndAge.w += 0.1f * subframeDeltaTime;
		positionAndAge.w = max(positionAndAge.w, 0.0001f);	// we can't allow zero time, or else the sign() won't work on it and the particles will be immortal
	
		{
			velocityAndDeltaAge.xyz -= velocityAndDeltaAge.xyz * drag * subframeDeltaTime;		
		}
	}
	
	float angle = frac(particleIndex * 0.2736f + random.w) * vs_spawnPositionParameters.z;
	float2 localDx = (frac(angle + float2(0.25f, 0.0f)) * 2 -1);
	
	// approximation of sin/cos, given local_dx in the range [-1,1] representing the full 360 degrees: (4 - 4 * abs(local_dx)) * local_dx
	localDx = (vs_spawnPositionParameters.w - vs_spawnPositionParameters.w * abs(localDx)) * localDx;
	
	float4	particleParameters = float4(particleType, vs_spawnPosition.w, localDx);
	
	MemexportPositionAndAge(particleIndex, positionAndAge);
	MemexportVelocityAndDeltaAge(particleIndex, velocityAndDeltaAge);
	MemexportParticleParameters(particleIndex, particleParameters);
}

#if defined(xenon)

void DefaultVS(in int index : INDEX)
{
	SpawnParticle(index);
}

float4 DefaultPS() : SV_Target0
{
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

#elif DX_VERSION == 11

[numthreads(CS_CHEAP_PARTICLE_SPAWN_THREADS,1,1)]
void DefaultCS(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		SpawnParticle(index);
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