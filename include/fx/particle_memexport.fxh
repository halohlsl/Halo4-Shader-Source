#if defined(xenon) || (DX_VERSION == 11)

#include "particle_memexport_registers.fxh"
#include "fx/particle_update_registers.fxh"
#include "fx/bonobo_function_evaluation.fxh"

#define _dies_at_rest_bit					0 //_particle_dies_at_rest_bit
#define _dies_on_structure_collision_bit	1 //_particle_dies_on_structure_collision_bit
#define _dies_on_media_collision_bit		2 //_particle_dies_on_media_collision_bit
#define _dies_on_air_collision_bit			3 //_particle_dies_on_air_collision_bit
#define _has_sweetener_bit					4 //_particle_has_sweetener_bit

#define _frame_animation_one_shot_bit		0 //_particle_frame_animation_one_shot_bit
#define _can_animate_backwards_bit			1 //_particle_can_animate_backwards_bit

#define _modifier_none			0
#define _modifier_add			1
#define _modifier_multiply		2

// The s_property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.
float get_constant_value(s_property p)		{ return p.m_innards.x; }
int get_is_constant(s_property p)			{ return EXTRACT_BITS(p.m_innards.y, 21, 22); }	// 1 bit always
int get_function_index_green(s_property p)	{ return EXTRACT_BITS(p.m_innards.z, 17, 22); }	// 5 bits often	
int get_input_index_green(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 17, 22); }	// 5 bits often	
int get_function_index_red(s_property p)	{ return EXTRACT_BITS(p.m_innards.y, 0, 5); }	// 5 bits often	
int get_input_index_red(s_property p)		{ return EXTRACT_BITS(p.m_innards.y, 5, 10); }	// 5 bits rarely	
int get_color_index_lo(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 0, 3); }	// 3 bits rarely	
int get_color_index_hi(s_property p)		{ return EXTRACT_BITS(p.m_innards.w, 3, 6); }	// 3 bits rarely	
int get_modifier_index(s_property p)		{ return EXTRACT_BITS(p.m_innards.z, 0, 2); }	// 2 bits often	
int get_input_index_modifier(s_property p)	{ return EXTRACT_BITS(p.m_innards.z, 2, 7); }	// 5 bits rarely	


#ifdef xenon

s_particle_memexported_state read_particle_state(int index)
{
	s_particle_memexported_state STATE;
	
	float4 pos_sample;
	float4 vel_sample;
	float4 rot_sample;
	float4 time_sample;
	float4 anm_sample;
	float4 anm2_sample;
	float4 rnd_sample;
	float4 rnd2_sample;
	float4 axis_sample;
	float4 col_sample;
	float4 col2_sample;

	asm {
		vfetch pos_sample, index.x, position1
		vfetch vel_sample, index.x, position2
		vfetch rot_sample, index.x, texcoord2
		vfetch time_sample, index.x, texcoord3
		vfetch anm_sample, index.x, texcoord4
		vfetch anm2_sample, index.x, texcoord5
		vfetch rnd_sample, index.x, position3
		vfetch rnd2_sample, index.x, position4
		vfetch axis_sample, index.x, normal1
		vfetch col_sample, index.x, color
		vfetch col2_sample, index.x, color1
	};

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;
	STATE.m_velocity= vel_sample.xyz;
	STATE.m_axis= axis_sample.xyz;
	STATE.m_birth_time= time_sample.x;
	STATE.m_age= time_sample.z;
	STATE.m_inverse_lifespan= time_sample.y;
	STATE.m_physical_rotation= rot_sample.x;
	STATE.m_manual_rotation= rot_sample.y;
	STATE.m_animated_frame= rot_sample.z;
	STATE.m_manual_frame= rot_sample.w;
	STATE.m_rotational_velocity= anm_sample.x;
	STATE.m_frame_velocity= anm_sample.y;
	STATE.m_color= col_sample;
	STATE.m_initial_color= col2_sample;
	STATE.m_random= rnd_sample;
	STATE.m_random2= rnd2_sample;
	STATE.m_size= pos_sample.w;
	STATE.m_aspect= vel_sample.w;
	STATE.m_intensity= time_sample.w;
	STATE.m_black_point= anm2_sample.x;
	STATE.m_white_point= anm2_sample.y;
	STATE.m_palette_v= anm2_sample.z;
	STATE.m_game_simulation_a= anm_sample.z;
	STATE.m_game_simulation_b= anm_sample.w;
	
	return STATE;
}


s_particle_memexported_state read_particle_state_fast(int index)
{
	s_particle_memexported_state STATE;
	
	float4 pos_sample;
//	float4 vel_sample;			// unused
	float4 rot_sample;
	float4 time_sample;
//	float4 anm_sample;			// unused
	float4 anm2_sample;
//	float4 rnd_sample;
//	float4 rnd2_sample;			// unused
	float4 axis_sample;			// unused
	float4 col_sample;
	float4 col2_sample;

	asm {
		vfetch pos_sample, index.x, position1
//		vfetch vel_sample, index.x, position2
		vfetch rot_sample, index.x, texcoord2
		vfetch time_sample, index.x, texcoord3
//		vfetch anm_sample, index.x, texcoord4
		vfetch anm2_sample, index.x, texcoord5
//		vfetch rnd_sample, index.x, position3
//		vfetch rnd2_sample, index.x, position4
		vfetch axis_sample, index.x, normal1
		vfetch col_sample, index.x, color
		vfetch col2_sample, index.x, color1
	};

//	float4 pos_sample= unknown_value;
	float4 vel_sample= 0;
//	float4 rot_sample= unknown_value;
//	float4 time_sample= unknown_value;
	float4 anm_sample= 0;
	float4 rnd_sample= 0;
	float4 rnd2_sample= 0;
//	float4 axis_sample= 0;
//	float4 col_sample= unknown_value;
//	float4 col2_sample= unknown_value;

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;				// used
	STATE.m_velocity= vel_sample.xyz;
	STATE.m_axis= axis_sample.xyz;					// used
	STATE.m_birth_time= time_sample.x;
	STATE.m_age= time_sample.z;						// used
	STATE.m_inverse_lifespan= time_sample.y;
	STATE.m_physical_rotation= rot_sample.x;		// used
	STATE.m_manual_rotation= rot_sample.y;			// used
	STATE.m_animated_frame= rot_sample.z;			// used
	STATE.m_manual_frame= rot_sample.w;				// used
	STATE.m_rotational_velocity= anm_sample.x;
	STATE.m_frame_velocity= anm_sample.y;
	STATE.m_color= col_sample;						// xyzw used
	STATE.m_initial_color= col2_sample;				// xyzw used
	STATE.m_random= rnd_sample;						// z used
	STATE.m_random2= rnd2_sample;
	STATE.m_size= pos_sample.w;						// used
	STATE.m_aspect= 1.0f;							// vel_sample.w;
	STATE.m_intensity= time_sample.w;				// used
	STATE.m_black_point= anm2_sample.x;				// used
	STATE.m_white_point= anm2_sample.y;				// used
	STATE.m_palette_v= anm2_sample.z;
	
	return STATE;
}

// The including function must define the stride_offset and stream_constant registers.
void write_particle_state(s_particle_memexported_state STATE, int index)
{
	static float4 stream_helper= {0, 1, 0, 0};
	float4 export[_state_max];

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	export[_state_pos]= float4(STATE.m_position, STATE.m_size);
	export[_state_vel]= float4(STATE.m_velocity, STATE.m_aspect);
	export[_state_rot]= float4(STATE.m_physical_rotation, STATE.m_manual_rotation, 
		STATE.m_animated_frame, STATE.m_manual_frame);
	export[_state_time]= float4(STATE.m_birth_time, STATE.m_inverse_lifespan, STATE.m_age, STATE.m_intensity);
	export[_state_anm]= float4(STATE.m_rotational_velocity, STATE.m_frame_velocity, STATE.m_game_simulation_a, STATE.m_game_simulation_b);
	export[_state_anm2]= float4(STATE.m_black_point, STATE.m_white_point, STATE.m_palette_v, 0.0f);
	export[_state_rnd]= float4(STATE.m_random);
	export[_state_rnd2]= float4(STATE.m_random2);
	export[_state_axis]= float4(STATE.m_axis, 0.0f);
	export[_state_col]= float4(STATE.m_color);
	export[_state_col2]= float4(STATE.m_initial_color);
#ifndef PARTICLE_WRITE_DISABLE_FOR_PROFILING
    // Store result.  Some of these writes are not needed by all clients
    // (eg. rnd should only be written by spawn, not update).
    for (int state= 0; state< _state_max; ++state)
    {
		int state_index= index * g_all_memexport[state].m_stride_offset.x + g_all_memexport[state].m_stride_offset.y;
		float4 stream_constant= g_all_memexport[state].m_stream_constant;
		float4 export= export[state];
		asm {
		alloc export=1
			mad eA, state_index, stream_helper, stream_constant
			mov eM0, export
		};
    }

#else	// do only enough writing to keep from culling any ALU calculations
	float4 all_export= float4(0,0,0,0);
    for (int state= 0; state< _state_max; ++state)
    {
		all_export+= export[state];
    }
	int state_index= index * g_all_memexport[0].m_stride_offset.x + g_all_memexport[0].m_stride_offset.y;
	float4 stream_constant= g_all_memexport[0].m_stream_constant;
	asm {
	alloc export=1
		mad eA, state_index, stream_helper, stream_constant
		mov eM0, all_export
	};
#endif
}

#elif DX_VERSION == 11

#include "fx/particle_pack.fxh"

s_particle_memexported_state read_particle_state(in int index)
{
	return unpack_particle_state(cs_particle_state_buffer[index]);
}

void write_particle_state(in s_particle_memexported_state state, in int index)
{
	cs_particle_state_buffer[index] = pack_particle_state(state);
}

#endif

float get_state_value(const s_particle_memexported_state particle_state, int index)
{
	if (index==_state_particle_age)
	{
		return particle_state.m_age;
	}
	else if (index>= _state_particle_correlation_1 && index <= _state_particle_correlation_4)
	{
		return particle_state.m_random[index-_state_particle_correlation_1];
	}
	else if (index>= _state_particle_random_seed_5 && index <= _state_particle_random_seed_8)
	{
		return particle_state.m_random2[index-_state_particle_random_seed_5];
	}
	else if (index==_state_particle_emit_time)
	{
		return particle_state.m_birth_time;
	}
	else if (index==_state_game_simulation_a)
	{
		return particle_state.m_game_simulation_a;
	}
	else if (index==_state_game_simulation_b)
	{
		return particle_state.m_game_simulation_b;
	}
	else if (index == _state_particle_velocity)
	{
		return length(particle_state.m_velocity + velocityOffset) * 0.1f;		// We scale velocity by 0.1 to put it into a more useful range (since functions take input in [0,1])
	}
	else	// a state which is independent of particle
	{
		return g_all_state.m_inputs[index].m_value;
	}
}

// This generates multiple inlined calls to evaluate and get_state_value, which are 
// large functions.  If the inlining becomes an issue, we can use the loop 
// trick documented below.
float particle_evaluate(const s_particle_memexported_state particle_state, int type)
{
	s_property property= g_all_properties[type];
	if (get_is_constant(property))
	{
		return get_constant_value(property);
	}
	else
	{
		float input= get_state_value(particle_state, get_input_index_green(property));
		float output;
		if (get_function_index_red(property)!= _type_identity)	// hack for ranged, since 0 isn't used
		{
			float interpolate= get_state_value(particle_state, get_input_index_red(property));
			output= evaluate_scalar_ranged(get_function_index_green(property), get_function_index_red(property), input, 
				interpolate);
		}
		else
		{
			output= evaluate_scalar(get_function_index_green(property), input);
		}
		if (get_modifier_index(property)!= _modifier_none)
		{
			float modify_by= get_state_value(particle_state, get_input_index_modifier(property));
			if (get_modifier_index(property)== _modifier_add)
			{
				output+= modify_by;
			}
			else // if (get_modifier_index(property)== _modifier_multiply)
			{
				output*= modify_by;
			}
		}
		return output;
	}
}

float3 particle_map_to_color_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 particle_map_to_vector2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float3 ParticleMapToVector3dLerp(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar); // this function does a lerp
}

float3 ParticleMapToVector3dDirectional(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector3d_range(get_color_index_lo(property), get_color_index_hi(property), scalar); // this function does a rotate
}

typedef float preevaluated_functions[_index_max];
preevaluated_functions preevaluate_particle_functions(s_particle_memexported_state STATE)
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
	float pre_evaluated_scalar[_index_max]= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, };
	[loop]
	for (int loop_counter= 0; loop_counter< _index_max; ++loop_counter)
	{
		pre_evaluated_scalar[loop_counter]= particle_evaluate(STATE, loop_counter);
	}

	return pre_evaluated_scalar;
}

#endif	// defined(xenon)