#include "fx\bonobo_function_types.fxh"

#if DX_VERSION == 11

// Match with c_light_volume_gpu::e_state.
#define _state_pos			0
#define _state_misc_2x16f	1
#define _state_col			2
#define _state_max			3

// Match with c_light_volume_definition::e_appearance_flags

// Match with c_editable_property_base::e_output_modifier
#define _modifier_none			0	//_output_modifier_none
#define _modifier_add			1	//_output_modifier_add
#define _modifier_multiply		2	//_output_modifier_multiply

// Match with s_gpu_property.  
// The s_property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.
struct s_property 
{
	float4 m_innards;
};

// Match with e_property in c_light_volume_gpu::set_shader_functions().
#define _index_profile_thickness			0
#define _index_profile_color				1
#define _index_profile_alpha				2
#define _index_profile_intensity			3
#define _index_max							4

CBUFFER_BEGIN_FIXED(LightVolumeUpdate, 13)
	CBUFFER_CONST_ARRAY(LightVolumeUpdate,		s_property,					g_all_properties, [_index_max],							_k_light_volume_update_all_properties)
	CBUFFER_CONST_ARRAY(LightVolumeUpdate,		s_function_definition,		g_all_functions, [_maximum_overall_function_count],		_k_light_volume_update_all_functions)
	CBUFFER_CONST_ARRAY(LightVolumeUpdate,		float4,						g_all_colors, [_maximum_overall_color_count],			_k_light_volume_update_all_colors)
CBUFFER_END

#endif