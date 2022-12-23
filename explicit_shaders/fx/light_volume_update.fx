#define LIGHT_VOLUME_CORE_CS
#include "fx\light_volume_core.fxh"
#include "fx\light_volume_update_registers.fxh"
#include "fx\bonobo_function_evaluation.fxh"

#if DX_VERSION == 11

float get_state_value(const ProfileMemexportedState profile_state, int index)
{
	if (index== eLVS_profilePercentile)
	{
		return profile_state.percentile;
	}
	else	// a state which is independent of profile
	{
		return vs_lightVolumeOverallState.inputs[index].value;
	}
}

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

// This generates multiple inlined calls to evaluate and get_state_value, which are 
// large functions.  If the inlining becomes an issue, we can use the loop 
// trick documented below.
float profile_evaluate(const ProfileMemexportedState profile_state, int type)
{
	s_property property= g_all_properties[type];
	if (get_is_constant(property))
	{
		return get_constant_value(property);
	}
	else
	{
		float input= get_state_value(profile_state, get_input_index_green(property));
		float output;
		if (get_function_index_red(property)!= _type_identity)	// hack for ranged, since 0 isn't used
		{
			float interpolate= get_state_value(profile_state, get_input_index_red(property));
			output= evaluate_scalar_ranged(get_function_index_green(property), get_function_index_red(property), input, 
				interpolate);
		}
		else
		{
			output= evaluate_scalar(get_function_index_green(property), input);
		}
		if (get_modifier_index(property)!= _modifier_none)
		{
			float modify_by= get_state_value(profile_state, get_input_index_modifier(property));
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

float3 light_volume_map_to_color_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_color_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 light_volume_map_to_point2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_point2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float2 light_volume_map_to_vector2d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector2d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

float3 light_volume_map_to_vector3d_range(int type, float scalar)
{
	s_property property= g_all_properties[type];
	return map_to_vector3d_range(get_color_index_lo(property), get_color_index_hi(property), scalar);
}

typedef float preevaluated_functions[_index_max];
preevaluated_functions preevaluate_light_volume_functions(ProfileMemexportedState STATE)
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
	float pre_evaluated_scalar[_index_max]= {0, 0, 0, 0, };
	[loop]
	for (int loop_counter= 0; loop_counter< _index_max; ++loop_counter)
	{
		pre_evaluated_scalar[loop_counter]= profile_evaluate(STATE, loop_counter);
	}

	return pre_evaluated_scalar;
}

struct s_profile_in
{
	int index;
};

void light_volume_main( s_profile_in IN )
{
	ProfileMemexportedState STATE;
	
	int buffer_index= ProfileIndexToBufferIndex(IN.index);

#if DX_VERSION == 11
	if (vs_lightVolumeOverallState.numProfiles <= 1)
	{
		STATE.percentile= 0;		
	} else
#endif
	{
		STATE.percentile= IN.index / (vs_lightVolumeOverallState.numProfiles - 1);
	}
	float pre_evaluated_scalar[_index_max]= preevaluate_light_volume_functions(STATE);

	// Update pos
	STATE.position.xyz= vs_lightVolumeOverallState.origin + vs_lightVolumeOverallState.direction * (vs_lightVolumeOverallState.offset + vs_lightVolumeOverallState.profileDistance * IN.index);

	// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
	STATE.color.xyz= light_volume_map_to_color_range(_index_profile_color, 
		pre_evaluated_scalar[_index_profile_color]);
	STATE.color.w= pre_evaluated_scalar[_index_profile_alpha];
		
	// Compute misc fields (better to do once here than multiple times in render)
	STATE.thickness= pre_evaluated_scalar[_index_profile_thickness];
	STATE.intensity= pre_evaluated_scalar[_index_profile_intensity];

	//return 
	WriteProfileMemexportedState(STATE, buffer_index);
}

[numthreads(CS_LIGHT_VOLUME_UPDATE_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + light_volume_index_range.x;
	if (index < light_volume_index_range.y)
	{
		s_profile_in input;
		input.index = index;
		light_volume_main(input);
	}
}

#else

void default_vs()
{
}

float4 default_cs() : SV_Target0
{
	return 0;
}

#endif

BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
#if DX_VERSION == 9
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
#elif DX_VERSION == 11
		SET_COMPUTE_SHADER(default_cs());
#endif
	}
}