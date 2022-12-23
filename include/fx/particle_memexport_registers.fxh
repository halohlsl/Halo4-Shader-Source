#if !defined(__PARTICLE_MEMEXPORT_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __PARTICLE_MEMEXPORT_FXH
#endif

#include "bonobo_function_types.fxh"
#include "raw_particle_state.fxh"

#ifndef DEFINED_PARTICLE_MEMEXPORT_STRUCTS
#define DEFINED_PARTICLE_MEMEXPORT_STRUCTS

// keep the index_ and bit_ #defines in sync!
#define _index_emitter_tint			0
#define _index_emitter_alpha		1
#define _index_emitter_size			2
#define _index_particle_color		3
#define _index_particle_intensity	4
#define _index_particle_alpha		5
#define _index_particle_scale		6
#define _index_particle_scale_x		7
#define _index_particle_scale_y		8
#define _index_particle_rotation	9
#define _index_particle_frame		10
#define _index_particle_black_point	11
#define _index_particle_white_point	12
#define _index_particle_aspect		13
#define _index_particle_self_acceleration 14
#define _index_particle_palette		15
#define _index_emitter_movement_turbulence 16
#define _index_max					17

#define _state_pos		0
#define _state_vel		1
#define	_state_rnd		2
#define _state_rnd2		3
#define _state_rot		4
#define _state_time		5
#define _state_anm		6
#define _state_anm2		7
#define _state_axis		8
#define _state_col		9
#define _state_col2		10
#define _state_max		11

// Match with c_particle_state_list::e_particle_state_input
#define _state_particle_age							0	//_particle_age
#define _state_system_age							1	//_system_age
#define _state_particle_random_seed					2	//_particle_random_seed
#define _state_system_random_seed					3	//_system_random_seed
#define _state_particle_correlation_1				4	//_particle_correlation_1
#define _state_particle_correlation_2				5	//_particle_correlation_2
#define _state_particle_correlation_3				6	//_particle_correlation_3
#define _state_particle_correlation_4				7	//_particle_correlation_4
#define _state_system_correlation_1					8	//_system_correlation_1
#define _state_system_correlation_2					9	//_system_correlation_2
#define _state_particle_emit_time					10	//_particle_emit_time
#define _state_location_lod							11	//_location_lod
#define _state_game_time							12	//_game_time
#define _state_object_a_out							13	//_object_a_out
#define _state_object_b_out							14	//_object_b_out
#define _state_particle_rotation					15	//_particle_rotation
#define _state_location_random_seed_1				16	//_location_random_seed_1
#define _state_particle_distance_from_emitter		17	//_particle_distance_from_emitter
#define _state_game_simulation_a					18	//_particle_simulation_a		// was _state_particle_rotation_dot_eye_forward		//_particle_rotation_dot_eye_forward		--- UNUSED, old halo 2 stuff (###ctchou $TODO what was this for?)
#define _state_game_simulation_b					19	//_particle_simulation_b		// was _state_particle_rotation_dot_eye_left		//_particle_rotation_dot_eye_left
#define _state_particle_velocity					20	//_particle_velocity
#define _state_invalid								21	//_invalid
#define _state_particle_random_seed_5				22	//_particle_random_seed_5
#define _state_particle_random_seed_6				23	//_particle_random_seed_6
#define _state_particle_random_seed_7				24	//_particle_random_seed_7
#define _state_particle_random_seed_8				25	//_particle_random_seed_8
#define _state_system_random_seed_3					26	//_system_random_seed_3
#define _state_system_random_seed_4					27	//_system_random_seed_4
#define _state_total_count							28	//k_total_count

struct s_property 
{
	PADDED(float,4,m_innards)
};

struct s_memexport
{
	PADDED(float,4,m_stream_constant)
	PADDED(float,2,m_stride_offset)
};

struct s_gpu_single_state
{
	PADDED(float,1,m_value)
};

struct s_all_state
{
	s_gpu_single_state m_inputs[_state_total_count];
};

#endif

#if DX_VERSION == 9

s_property g_all_properties[_index_max] : register(c148);
s_memexport g_all_memexport[_state_max] : register(c166);

// Match with s_gpu_single_state in c_particle_emitter_gpu::set_shader_update_state()
s_all_state g_all_state : register(c188);

s_function_definition g_all_functions[_maximum_overall_function_count] : register(c40); // 100 parameters
float4 g_all_colors[_maximum_overall_color_count] : register(c140); // 8 parameters

#elif DX_VERSION == 11

#define CS_PARTICLE_SPAWN_THREADS 64
#define CS_PARTICLE_UPDATE_THREADS 64

CBUFFER_BEGIN_FIXED(ParticleMemExport, 13)
	CBUFFER_CONST_ARRAY(ParticleMemExport,		s_property,					g_all_properties, [_index_max],							_k_particle_memexport_all_properties)
	CBUFFER_CONST_ARRAY(ParticleMemExport,		s_function_definition,		g_all_functions, [_maximum_overall_function_count],		_k_particle_memexport_all_functions)
	CBUFFER_CONST_ARRAY(ParticleMemExport,		float4,						g_all_colors, [_maximum_overall_color_count],			_k_particle_memexport_all_colors)
CBUFFER_END

CBUFFER_BEGIN(ParticleMemExportState)
	CBUFFER_CONST(ParticleMemExportState,		s_all_state,				g_all_state,											k_particle_memexport_all_state)
CBUFFER_END

STRUCTURED_BUFFER(cs_particle_address_buffer,		k_cs_particle_address_buffer,		uint,					4)
STRUCTURED_BUFFER(cs_particle_state_spawn_buffer,	k_cs_particle_state_spawn_buffer,	s_raw_particle_state,	5)
RW_STRUCTURED_BUFFER(cs_particle_state_buffer,		k_cs_particle_state_buffer,			s_raw_particle_state,	0)

#endif

#endif
