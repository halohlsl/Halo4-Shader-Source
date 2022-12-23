// this file is a travesty, because it uses many shader constants, so we can't include willy-nilly

struct s_particle_vertex
{
	int index:				INDEX;
	float2 address:			TEXCOORD1;
};

#if DX_VERSION == 9
#define SV_Target COLOR
#define SV_Target0 COLOR0
#define SV_Target1 COLOR1
#define SV_Target2 COLOR2
#define SV_Target3 COLOR3
#define SV_Depth DEPTH
#define SV_Depth0 DEPTH0
#define SV_Position POSITION
#define SV_Position0 POSITION0
#define SCREEN_POSITION_INPUT(_name) float2 _name : VPOS
#define BEGIN_TECHNIQUE technique
#define SET_VERTEX_SHADER(_func) VertexShader = compile vs_3_0 _func
#define SET_PIXEL_SHADER(_func) PixelShader = compile ps_3_0 _func
#endif

#if DX_VERSION == 9

typedef sampler2D texture_sampler_2d; 

float4 sample2DLOD(texture_sampler_2d s, float2 uv, float lod, uniform bool ApplyGamma = true)
{
	float4 value = tex2Dlod(s, float4(uv, 0, lod));
	//value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

#elif DX_VERSION == 11

#include "core/core.fxh"
#include "fx/particle_index_registers.fxh"

#endif

#if defined(xenon) || (DX_VERSION == 11)

#ifdef xenon
#define pi 3.14159265358979323846

#define _epsilon 0.00001f
#define _1_minus_epsilon (1.0f - _epsilon)

#define power_2_0	1
#define power_2_1	(2 * power_2_0)
#define power_2_2	(2 * power_2_1)
#define power_2_3	(2 * power_2_2)
#define power_2_4	(2 * power_2_3)
#define power_2_5	(2 * power_2_4)
#define power_2_6	(2 * power_2_5)
#define power_2_7	(2 * power_2_6)
#define power_2_8	(2 * power_2_7)
#define power_2_9	(2 * power_2_8)
#define power_2_10	(2 * power_2_9)
#define power_2_11	(2 * power_2_10)
#define power_2_12	(2 * power_2_11)
#define power_2_13	(2 * power_2_12)
#define power_2_14	(2 * power_2_13)
#define power_2_15	(2 * power_2_14)	
#define power_2_16	(2 * power_2_15)	
#define power_2_17	(2 * power_2_16)	
#define power_2_18	(2 * power_2_17)	
#define power_2_19	(2 * power_2_18)	
#define power_2_20	(2 * power_2_19)	
#define power_2_21	(2 * power_2_20)	
#define power_2_22	(2 * power_2_21)
#define TEST_BIT(flags, bit) (frac(flags / (2 * power_2_##bit)) - 0.5f >= 0.0f)
#define EXTRACT_BITS(bitfield, lo_bit, hi_bit) extract_bits(bitfield, power_2_##lo_bit, power_2_##hi_bit)
float extract_bits(float bitfield, int lo_power /*const power of 2*/, int hi_power /*const power of 2*/)
{
	float result = bitfield; // calling this an 'int' adds an unnecessary 'truncs'
	if (lo_power != power_2_0 /*2^0 compile time test*/)
	{
		// Should be 2 instructions: mad, floors
		result /= lo_power;
		result = floor(result);
	}
	if (hi_power != power_2_22 /*2^22 compile time test*/)
	{
		// Should be 3 instructions: mulsc, frcs, mulsc
		result /= (hi_power / lo_power);
		result = frac(result);
		result *= (hi_power / lo_power);
	}
	return result;
}
#endif

#include "fx/particle_types.fxh"
#include "fx/particle_memexport.fxh"

void ApplyGlobalForces(inout s_particle_memexported_state STATE, in float dt)
{
		[branch]
		if (globalForces)
		{
			for (int globalForceIndex = 0; globalForceIndex < GLOBAL_FORCE_COUNT; ++globalForceIndex)
			{
				float3 direction = STATE.m_position - globalForceData[globalForceIndex].position_forceAmount.xyz;
				float distance;
				float multiplier;
				if (globalForceData[globalForceIndex].forceIsCylinder > 0.5) // it will be either 0 or 1
				{
					// if it's a cylinder, get rid of the parallel part
					direction -= dot(direction, globalForceData[globalForceIndex].forceCylinderDirection) * globalForceData[globalForceIndex].forceCylinderDirection;
					distance = length(direction);
					multiplier = 1.0f;
				}
				else
				{
					// if it's a sphere, apply falloff
					distance = length(direction);
					multiplier = saturate((globalForceData[globalForceIndex].forceFalloffEnd - distance) / globalForceData[globalForceIndex].forceFalloffRange);
				}
				direction /= distance;
				
				// it's very easy to get out of hand, so we'll act like a planet that you go into -- when you pass 0.5 world units, scale the force down
				const float minRadius = 0.5;
				float imaginaryRadius = max(distance, minRadius + (minRadius - distance)); // don't go too crazy
				
				multiplier /= (imaginaryRadius * imaginaryRadius);
				
				STATE.m_velocity += direction * globalForceData[globalForceIndex].position_forceAmount.w * multiplier * dt;
			}
		}
}

// Assumes position is above the tile in world space.
void clamp_to_tile(inout float3 position)
{
#if defined(CLAMP_IN_WORLD_Z_DIRECTION)	// This leads to particle clumping
	float3 tile_pos= frac(mul(float4(position, 1.0f), world_to_tile));
	float3 tile_z= mul(float4(0.0f, 0.0f, 1.0f, 0.0f), world_to_tile);
	
	// Clamp down to the three positive planes.  Should have no effect on things already below.
	float3 lift_to_pos_planes= (1.0f - tile_pos)/tile_z;
	float min_lift= min(lift_to_pos_planes.x, lift_to_pos_planes.z);	// only need y if there's roll; otherwise this is divide-by-zero
	tile_pos+= tile_z * min_lift;
	
	position= mul(float4(tile_pos, 1.0f), tile_to_world);
#else	//if CLAMP_IN_TILE_Z_DIRECTION
	position= mul(float4(frac(mul(float4(position, 1.0f), world_to_tile)).xy, 1.0f, 1.0f), tile_to_world);
#endif
}

void wrap_to_tile(inout float3 position)
{
	// This code compiles to 9 ALU instructions ###ctchou $TODO why 9???  shouldn't it be 3 ALUs?  maybe even less if it scalar pairs all the individual channels of the frac
	position= mul(float4(frac(mul(float4(position, 1.0f), world_to_tile)), 1.0f), tile_to_world);
}

// Used to recycle particles to near the camera
void update_particle_state_tiling(inout s_particle_memexported_state STATE)
{
	if (tiled)
	{
		wrap_to_tile(STATE.m_position);
	}
}

#define HIDE_OCCLUDED_PARTICLES
void update_particle_state_collision(inout s_particle_memexported_state STATE)
{
	// This code compiles to 2 sequencer blocks and 9 ALU instructions.  We can get to 7 ALU by putting the 1.0f and 2.0f below into
	// the matrix
/*	if (collision)					// removed (leaving here for reference in case we want to eventually use the new weather occlusion system)
	{
		float3 weather_space_pos= mul(float4(STATE.m_position, 1.0f), world_to_occlusion).xyz;
		float occlusion_z= sample2DLOD(sampler_weather_occlusion, weather_space_pos.xy, 0, false).x;
		if (occlusion_z< weather_space_pos.z)
		{
			// particle is occluded by geometry...
#if defined(TINT_OCCLUDED_PARTICLES)
			STATE.m_color= float4(1.0f, 0.0f, 0.0f, 1.0f);	// Make particle easily visible for debugging
#elif defined(KILL_OCCLUDED_PARTICLES)
			STATE.m_age= 1.0f;	// Kill particle
#elif defined(HIDE_OCCLUDED_PARTICLES)
			STATE.m_color.w= 0.0f;	// These get killed in the render, but are allowed to continue in the update until they tile
#else	//if defined(ATTACH_OCCLUDED_PARTICLES)
			weather_space_pos.z= occlusion_z;
			STATE.m_position= mul(float4(weather_space_pos, 1.0f), occlusion_to_world).xyz;
			STATE.m_velocity= float3(0.0f, 0.0f, -0.001f);
			if (!STATE.m_collided)
			{
				STATE.m_age= 0.0f;
				STATE.m_collided= true;
			}
#endif
		}
	}
*/
}

void update_particle_looping(inout s_particle_memexported_state STATE)
{
#if defined(ATTACH_OCCLUDED_PARTICLES)
	if (looping)
	{
		if (STATE.m_age>= 1.0f)
		{
			STATE.m_age= frac(STATE.m_age);
			if (STATE.m_collided)
			{
				clamp_to_tile(STATE.m_position);
				STATE.m_collided= false;
			}
		}
	}
#endif
}

void update_particle_state(inout s_particle_memexported_state STATE)
{
	// This is a hack to allow one frame of no updating after spawn.
	float dt= (STATE.m_size>= 0.0f) ? delta_time : 0.0f;

	// Update particle life
	STATE.m_age+= STATE.m_inverse_lifespan * dt
#if defined(THROTTLE_BY_AGING)
		* g_gpuThrottleAgingMultiplier
#endif // defined(THROTTLE_BY_AGING)
		;
	
	if (liveForever)
	{
		STATE.m_age = frac(STATE.m_age);
		// back-of-the-envelope, a 16f should represent 0.999 < 1 successfully, but I don't trust the ALUs to be exactly that precise; certainly saw rounding errors
		// when this check wasn't attempted at all
		if (STATE.m_age > 0.99f)
		{
			STATE.m_age = 0.0f;
		}
	}

	float pre_evaluated_scalar[_index_max]= preevaluate_particle_functions(STATE);

	if (STATE.m_age< 1.0f)
	{
		if (!disableVelocity)
		{
			// Update particle pos
			STATE.m_position.xyz+= STATE.m_velocity.xyz * dt * g_update_state.m_scaleMultiplier;
		}
		
		if (g_clipSphere.w > 0.01 && length(STATE.m_position.xyz - g_clipSphere.xyz) > g_clipSphere.w)
		{
			STATE.m_age += 3.0f * STATE.m_inverse_lifespan * dt; // quadruple speed!
		}
		
		if (turbulence)
		{
			float4 turbulence_texcoord;
			turbulence_texcoord.xy=	float2(STATE.m_birth_time, STATE.m_random2.x) * turbulence_xform.xy + turbulence_xform.zw;
			turbulence_texcoord.zw=	0.0f;
			STATE.m_position.xyz += (sample2DLOD(sampler_turbulence, turbulence_texcoord, 0, false).xyz - 0.5f) * pre_evaluated_scalar[_index_emitter_movement_turbulence] * dt;
		}
		
		ApplyGlobalForces(STATE, dt);

		// Update velocity (saturate is so friction can't cause reverse of direction)
		STATE.m_velocity+= ParticleMapToVector3dLerp(_index_particle_self_acceleration, pre_evaluated_scalar[_index_particle_self_acceleration])
			* dt;
		STATE.m_velocity.z-= g_update_state.m_gravity * dt;
		STATE.m_velocity.xyz-= saturate(g_update_state.m_airFriction * dt) * STATE.m_velocity.xyz;
		
		// Update rotational velocity (saturate is so friction can't cause reverse of direction)
		STATE.m_rotational_velocity-= saturate(g_update_state.m_rotationalFriction * dt) * STATE.m_rotational_velocity;
		
		// Update rotation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		STATE.m_physical_rotation= 
			frac(STATE.m_physical_rotation + STATE.m_rotational_velocity * dt);
		STATE.m_manual_rotation= frac(pre_evaluated_scalar[_index_particle_rotation]);
		
		// Update frame animation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		STATE.m_animated_frame= frac(STATE.m_animated_frame + STATE.m_frame_velocity * dt);
		STATE.m_manual_frame= frac(pre_evaluated_scalar[_index_particle_frame]);
		
		// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
		STATE.m_color.xyz= particle_map_to_color_range(_index_emitter_tint, pre_evaluated_scalar[_index_emitter_tint])
			* particle_map_to_color_range(_index_particle_color, pre_evaluated_scalar[_index_particle_color]);
		STATE.m_color.w= pre_evaluated_scalar[_index_emitter_alpha] 
			* pre_evaluated_scalar[_index_particle_alpha];
			
		// Update other particle state
		// note: we bake scale_x and scale_y into size and aspect
		STATE.m_size= pre_evaluated_scalar[_index_emitter_size] * pre_evaluated_scalar[_index_particle_scale] * pre_evaluated_scalar[_index_particle_scale_y] * g_update_state.m_scaleMultiplier;
		STATE.m_aspect= pre_evaluated_scalar[_index_particle_aspect] * (pre_evaluated_scalar[_index_particle_scale_x] / pre_evaluated_scalar[_index_particle_scale_y]);
		STATE.m_intensity= pre_evaluated_scalar[_index_particle_intensity];
		STATE.m_black_point= saturate(pre_evaluated_scalar[_index_particle_black_point]);
		STATE.m_white_point= saturate(pre_evaluated_scalar[_index_particle_white_point]);
		STATE.m_palette_v= saturate(pre_evaluated_scalar[_index_particle_palette]);
#if DX_VERSION == 9
		// avoid wrap on xenon, but don't do this on D3D11 because it prevents the values from ever reaching 1
		STATE.m_black_point *= _1_minus_epsilon; // avoid wrap
		STATE.m_white_point *= _1_minus_epsilon_1_minus_epsilon; // avoid wrap
		STATE.m_palette_v *= _1_minus_epsilon;// avoid wrap
#endif	
	}
	else
	{
		// Particle death, kill pixel
		// Can't do this for EDRAM, since anything we write gets resolved back
		// For MemExport, should skip the writeback in this case.
	}
}

void particle_main( s_particle_vertex IN )
{
	s_particle_memexported_state STATE;

	STATE= read_particle_state(IN.index);

	update_particle_state(STATE);
	update_particle_state_tiling(STATE);
	update_particle_state_collision(STATE);
	update_particle_looping(STATE);
	
	//return 
	write_particle_state(STATE, IN.index);
}
#endif // defined(xenon)

#if DX_VERSION == 9

// For EDRAM method, the main work must go in the pixel shader, since only 
// pixel shaders can write to EDRAM.
// For the MemExport method, we don't need a pixel shader at all.
// This is signalled by a "void" return type or "multipass" config?

#if !defined(xenon)
float4 default_vs( s_particle_vertex IN ) :SV_Position
{
	return float4(1, 2, 3, 4);
}
#else
void default_vs( s_particle_vertex IN )
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};
	particle_main(IN);
}
#endif

// Should never be executed
float4 default_ps( void ) :SV_Target0
{
	return float4(0,1,2,3);
}

#elif DX_VERSION == 11

[numthreads(CS_PARTICLE_UPDATE_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		s_particle_vertex input;
		input.index = index;
		input.address = 0;
		particle_main(input);
	}
}

#endif

BEGIN_TECHNIQUE _default
{
	pass particle
	{
#if DX_VERSION == 9	
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
#elif DX_VERSION ==11
		SET_COMPUTE_SHADER(default_cs());
#endif
	}
}