#include "fx/cheap_particle_core.fxh"
#include "cheap_particles_spawn_registers.fxh"

#if defined(xenon) || (DX_VERSION == 11)
void GetPositionAndVelocity(int particleIndex, float4 random, out float3 position, out float3 velocity)
{
	position = vs_positions[particleIndex - vs_spawnOffset.x];
	velocity = vs_velocities[particleIndex - vs_spawnOffset.x];
}
#endif // defined(xenon)

#include "cheap_particles_spawn_shared.fxh"