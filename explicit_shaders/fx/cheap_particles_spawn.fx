#include "fx/cheap_particle_core.fxh"

#if DX_VERSION == 11
	#define positionSampler cs_positionSampler
	#define velocitySampler cs_velocitySampler
#else
	#define positionSampler vs_positionSampler
	#define velocitySampler vs_velocitySampler
#endif

#if defined(xenon) || (DX_VERSION == 11)
void GetPositionAndVelocity(int particleIndex, float4 random, out float3 position, out float3 velocity)
{
	float4x4 transform;
	float3 left;
	left = cross(vs_spawnUp, vs_spawnForward);
	transform[0] = float4(vs_spawnUp.xyz, 0.0f);
	transform[1] = float4(left.xyz, 0.0f);
	transform[2] = float4(vs_spawnForward.xyz, 0.0f);
	transform[3] = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// calculate random position
	float4 positionRandom = GenerateRandomInRange(particleIndex, 0.5f, positionSampler, vs_positionSamplerTransform, -1.0f, 1.0f);

	if (vs_positionInLocalSpace)
	{
		positionRandom = mul(positionRandom, transform);	
	}

	// apply scale and flatten
	position = positionRandom.xyz * vs_spawnPositionParameters.x;
	position = position - vs_spawnForward.xyz * dot(position, vs_spawnForward.xyz) * vs_spawnPositionParameters.y;
	
	// offset by spawn origin
	position = position + vs_spawnPosition.xyz;

	float directionality = vs_spawnVelocityParameters.x + vs_spawnVelocityParameters.y * random.x;
	float speed = vs_spawnVelocityParameters.z + vs_spawnVelocityParameters.w * random.y;

	float4 velocityRandom = GenerateRandomInRange(particleIndex, 0.5f, velocitySampler, vs_velocitySamplerTransform, -1.0f, 1.0f);

	if (vs_velocityInLocalSpace)
	{
		velocityRandom = mul(velocityRandom, transform);
	}

	velocity = lerp(velocityRandom.xyz, vs_spawnForward.xyz, directionality);
	if (vs_spawnVelocityNormalize)
	{
		velocity = normalize(velocity);
	}
	velocity *= speed;
}
#endif // defined(xenon)

#include "cheap_particles_spawn_shared.fxh"