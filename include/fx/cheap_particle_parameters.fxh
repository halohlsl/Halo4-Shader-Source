#if !defined(__CHEAP_PARTICLE_PARAMETERS_FXH)

#ifndef DEFINE_CPP_CONSTANTS
#define __CHEAP_PARTICLE_PARAMETERS_FXH
#endif

#if DX_VERSION == 9

#include "fx_parameters.fxh"

//// global parameters
//VERTEX_CONSTANT(float4, NaN,									100);		// Not a Number
DECLARE_PARAMETER(float4, vs_deltaTime, c101);		// delta time, unused, unused, unused
//
//// orientation parameters (###ctchou $TODO should be a matrix?)
DECLARE_PARAMETER(float4, vs_spawnPosition, c102); // position.xyz, illumination
DECLARE_PARAMETER(float4, vs_spawnForward, c103); // forward.xyz, unused
DECLARE_PARAMETER(float4, vs_spawnUp, c104); // up.xyz, unused
//
//// emitter parameters
DECLARE_PARAMETER(float4, vs_spawnPositionParameters, c105); // scale, flatten, rot_scale, size scale (0-2)
DECLARE_PARAMETER(float4, vs_spawnVelocityParameters, c106); // directionality min, range, speed min, range
DECLARE_PARAMETER(float4, vs_spawnTimeParameters, c107); // time_offset min, range, delta_age_min, delta_age_range
DECLARE_PARAMETER(float4, vs_spawnTypeThresholds, c108); // type threshold
DECLARE_PARAMETER(float4, vs_spawnTypeConstants, c109); // type constants
//
DECLARE_PARAMETER(bool, vs_positionInLocalSpace, b110);
DECLARE_PARAMETER(bool, vs_spawnVelocityNormalize, b111);
DECLARE_PARAMETER(bool, vs_velocityInLocalSpace, b112);
//
//
//// buffer parameters
DECLARE_PARAMETER(float4, vs_spawnOffset, c113);
//
//// random transforms
//
DECLARE_PARAMETER(float4, vs_collisionDepthConstants, c117);
//
//
//
//VERTEX_CONSTANT(float4x4, view_projection,						140);
//
//
//// Mem export address offsets
DECLARE_PARAMETER(float4, vs_positionAgeAddressOffset, c150); // x - memexport address offset for outputting particle data during spawning
DECLARE_PARAMETER(float4, vs_velocityAndDeltaAgeAddressOffset, c151);
DECLARE_PARAMETER(float4, vs_parametersAddressOffset, c152);
//
//
DECLARE_PARAMETER(sampler2D, vs_typeSampler, s0); // render, spawn, update

DECLARE_PARAMETER(sampler, vs_randomSampler, s1); // spawn
DECLARE_PARAMETER(float4, vs_randomSamplerTransform, c114);
DECLARE_PARAMETER(sampler, vs_positionSampler, s2); // spawn
DECLARE_PARAMETER(float4, vs_positionSamplerTransform, c115);
DECLARE_PARAMETER(sampler, vs_velocitySampler, s3); // spawn
DECLARE_PARAMETER(float4, vs_velocitySamplerTransform, c116);

DECLARE_PARAMETER(sampler, vs_turbulenceSampler, s1); // update
DECLARE_PARAMETER(float4, vs_turbulenceTransform[8], c118);
DECLARE_PARAMETER(sampler2D, vs_collisionDepthBuffer, s2); // update
DECLARE_PARAMETER(sampler2D, vs_collisionNormalBuffer, s3); // update

DECLARE_PARAMETER(sampler3D, ps_renderTexture, s0); // render

DECLARE_PARAMETER(float3x3,	vs_worldspace_normal_axis, c126);

DECLARE_PARAMETER(float4, vs_hiddenFromCompilerNaN, c32); // 1 variable

#elif DX_VERSION == 11

#define CS_CHEAP_PARTICLE_INIT_THREADS 64
#define CS_CHEAP_PARTICLE_SPAWN_THREADS 64
#define CS_CHEAP_PARTICLE_UPDATE_THREADS 64

#ifndef DEFINED_CHEAP_PARTICLE_STRUCTS
#define DEFINED_CHEAP_PARTICLE_STRUCTS
struct s_cheap_particle_data
{
	float4 position_age;
	uint2 velocity_delta_age;
	uint parameters;
};
#endif

CBUFFER_BEGIN(CheapParticleGlobalVS)
	CBUFFER_CONST(CheapParticleGlobalVS,		float4, 	vs_deltaTime, 							k_vs_cheap_particle_delta_time)
	CBUFFER_CONST(CheapParticleGlobalVS,		float4, 	vs_collisionDepthConstants, 			k_vs_cheap_particle_collision_depth_constants)
	CBUFFER_CONST_ARRAY(CheapParticleGlobalVS,	float4, 	vs_turbulenceTransform, [8], 			k_vs_cheap_particle_turbulence_transform)
	CBUFFER_CONST(CheapParticleGlobalVS,		float4,		vs_hiddenFromCompilerNaN,				k_vs_cheap_particle_hidden_from_compiler_nan)
	CBUFFER_CONST(CheapParticleGlobalVS,		float4,		vs_arrayTextureParameters,				k_vs_cheap_particle_array_texture_parameters)
CBUFFER_END		
		
CBUFFER_BEGIN(CheapParticleEmitterVS)		
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnPosition, 						k_vs_cheap_particle_spawn_position)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnForward, 						k_vs_cheap_particle_spawn_forward)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnUp, 							k_vs_cheap_particle_spawn_up)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnPositionParameters, 			k_vs_cheap_particle_spawn_position_parameters)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnVelocityParameters, 			k_vs_cheap_particle_spawn_velocity_parameters)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnTimeParameters, 				k_vs_cheap_particle_spawn_time_parameters)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnTypeThresholds, 				k_vs_cheap_particle_spawn_type_thresholds)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_spawnTypeConstants, 					k_vs_cheap_particle_spawn_type_constants)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_randomSamplerTransform, 				k_vs_cheap_particle_random_sampler_transform)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_positionSamplerTransform, 			k_vs_cheap_particle_position_sampler_transform)
	CBUFFER_CONST(CheapParticleEmitterVS,		float4, 	vs_velocitySamplerTransform, 			k_vs_cheap_particle_velocity_sampler_transform)
	CBUFFER_CONST(CheapParticleEmitterVS,		float3x3,	vs_worldspace_normal_axis, 				k_vs_cheap_particle_worldspace_normal_axis)
	CBUFFER_CONST(CheapParticleEmitterVS,		float,		vs_worldspace_normal_axis_pad,			k_vs_cheap_particle_worldspace_normal_axis_pad)
	CBUFFER_CONST(CheapParticleEmitterVS,		bool, 		vs_positionInLocalSpace, 				k_vs_cheap_particle_bool_position_in_local_space)
	CBUFFER_CONST(CheapParticleEmitterVS,		bool, 		vs_spawnVelocityNormalize, 				k_vs_cheap_particle_bool_spawn_velocity_normalize)
	CBUFFER_CONST(CheapParticleEmitterVS,		bool, 		vs_velocityInLocalSpace, 				k_vs_cheap_particle_bool_velocity_in_local_space)
CBUFFER_END		
		
CBUFFER_BEGIN(CheapParticleBufferVS)		
	CBUFFER_CONST(CheapParticleBufferVS,			float4, 	vs_spawnOffset, 						k_vs_cheap_particle_spawn_offset)
CBUFFER_END

CBUFFER_BEGIN(CheapParticleIndexRange)
	CBUFFER_CONST(CheapParticleIndexRange,		uint2,		particle_index_range,					k_cheap_particle_index_range)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D,			vs_typeSampler, 			k_vs_cheap_particle_type_sampler,				0)

COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_typeSampler, 			k_cs_cheap_particle_type_sampler,				0)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_randomSampler, 			k_cs_cheap_particle_random_sampler,				1)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_positionSampler, 		k_cs_cheap_particle_position_sampler,			2)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_velocitySampler,			k_cs_cheap_particle_velocity_sampler,			3)
COMPUTE_TEXTURE_AND_SAMPLER(_2D_ARRAY,	cs_turbulenceSampler, 		k_cs_cheap_particle_turbulence_sampler,			1)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_collisionDepthBuffer, 	k_cs_cheap_particle_collision_depth_buffer,		2)
COMPUTE_TEXTURE_AND_SAMPLER(_2D,		cs_collisionNormalBuffer, 	k_cs_cheap_particle_collision_normal_buffer,	3)

PIXEL_TEXTURE_AND_SAMPLER(_2D_ARRAY,	ps_renderTexture, 			k_ps_cheap_particle_render_texture,				0)

RW_STRUCTURED_BUFFER(cs_particle_state_buffer,		k_cs_particle_state_buffer,		s_cheap_particle_data,	0)
STRUCTURED_BUFFER(vs_particle_state_buffer,			k_vs_particle_state_buffer,		s_cheap_particle_data,	16)

#endif

#endif 	// !defined(__CHEAP_PARTICLE_PARAMETERS_FXH)