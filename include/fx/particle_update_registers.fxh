#ifndef DEFINED_PARTICLE_UPDATE_STRUCTS
#define DEFINED_PARTICLE_UPDATE_STRUCTS

struct s_update_state
{
	float4 m_gravity_airFriction_rotationalFriction_scaleMultiplier;
};

struct GlobalForceData
{
	float4 position_forceAmount;
	float4 globalForceAuxiliaryData;
};

#endif

#ifndef DEFINE_CPP_CONSTANTS
#define forceIsCylinder globalForceAuxiliaryData.w
#define forceCylinderDirection globalForceAuxiliaryData.xyz
#define forceFalloffEnd globalForceAuxiliaryData.x
#define forceFalloffRange globalForceAuxiliaryData.y
#define m_gravity m_gravity_airFriction_rotationalFriction_scaleMultiplier.x
#define m_airFriction m_gravity_airFriction_rotationalFriction_scaleMultiplier.y
#define m_rotationalFriction m_gravity_airFriction_rotationalFriction_scaleMultiplier.z
#define m_scaleMultiplier m_gravity_airFriction_rotationalFriction_scaleMultiplier.w
#endif
	
#define GLOBAL_FORCE_COUNT 4

#if DX_VERSION == 9

// rain particles visibility occlusion map
sampler sampler_weather_occlusion : register(s1);	//	k_vs_sampler_weather_occlusion in hlsl_constant_oneshot.h
sampler sampler_turbulence : register(s2);			//	k_vs_sampler_weather_occlusion in hlsl_constant_oneshot.h

float3 velocityOffset : register(c20);
float delta_time : register(c21);
float4 hidden_from_compiler : register(c22);	// the compiler will complain if these are literals
float4x3 tile_to_world : register(c23);	//= {float3x3(Camera_Forward, Camera_Left, Camera_Up) * tile_size, Camera_Position};
float4x3 world_to_tile : register(c26);	//= {transpose(float3x3(Camera_Forward, Camera_Left, Camera_Up) * inverse_tile_size), -Camera_Position};
float4x3 occlusion_to_world : register(c29);
float4x3 world_to_occlusion : register(c32);
float4 turbulence_xform : register(c36);

bool tiled : register(b20);
bool liveForever : register(b21);
bool turbulence : register(b22);
bool globalForces : register(b23);
bool disableVelocity : register(b24);

s_update_state g_update_state : register(c37);
float4 g_clipSphere : register(c38);
float g_gpuThrottleAgingMultiplier : register(c39);

GlobalForceData globalForceData[GLOBAL_FORCE_COUNT] : register(c216);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ParticleUpdateVS)
	CBUFFER_CONST(ParticleUpdateVS,			float3,				velocityOffset,							k_vs_particle_update_velocity_offset)
	CBUFFER_CONST(ParticleUpdateVS,			float,				pad1,									k_vs_particle_update_pad1)
	CBUFFER_CONST(ParticleUpdateVS,			float,				delta_time,								k_vs_particle_update_delta_time)
	CBUFFER_CONST(ParticleUpdateVS,			float3,				pad2,									k_vs_particle_update_pad2)
	CBUFFER_CONST(ParticleUpdateVS,			float4,				hidden_from_compiler, 					k_vs_particle_update_hidden_from_compiler)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,			tile_to_world,							k_vs_particle_update_tile_to_world)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,			world_to_tile,							k_vs_particle_update_world_to_tile)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,			occlusion_to_world,						k_vs_particle_update_occlusion_to_world)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,			world_to_occlusion,						k_vs_particle_update_world_to_occlusion)
	CBUFFER_CONST(ParticleUpdateVS,			float4,				turbulence_xform,						k_vs_particle_update_turbulence_xform)
	CBUFFER_CONST(ParticleUpdateVS,			s_update_state,		g_update_state,							k_vs_particle_update_state)
	CBUFFER_CONST(ParticleUpdateVS,			float4,				g_clipSphere,							k_vs_particle_update_clip_sphere)
	CBUFFER_CONST(ParticleUpdateVS,			float,				g_gpuThrottleAgingMultiplier,			k_vs_particle_update_gpu_throttle_aging_multiplier)
	CBUFFER_CONST_ARRAY(ParticleUpdateVS,	GlobalForceData,	globalForceData, [GLOBAL_FORCE_COUNT],	k_vs_particle_update_global_force_data)
	CBUFFER_CONST(ParticleUpdateVS,			bool,				tiled,									k_vs_particle_update_bool_tiled)
	CBUFFER_CONST(ParticleUpdateVS,			bool,				liveForever,							k_vs_particle_update_bool_live_forever)
	CBUFFER_CONST(ParticleUpdateVS,			bool,				turbulence,								k_vs_particle_update_bool_turbulence)
	CBUFFER_CONST(ParticleUpdateVS,			bool,				globalForces,							k_vs_particle_update_bool_global_forces)
	CBUFFER_CONST(ParticleUpdateVS,			bool,				disableVelocity,						k_vs_particle_update_bool_disable_velocity)
CBUFFER_END

COMPUTE_TEXTURE_AND_SAMPLER(_2D,	sampler_weather_occlusion,		k_particle_update_weather_occclusion_sampler,	1)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,	sampler_turbulence,				k_particle_update_turbulence_sampler,			2)

#endif
