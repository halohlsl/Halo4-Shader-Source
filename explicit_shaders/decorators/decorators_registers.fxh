// light data goes where node data would normally be
#define k_maximum_simple_light_count	8

#if DX_VERSION == 9

DECLARE_PARAMETER(int, v_simple_light_count, i0);
DECLARE_PARAMETER(float4, v_simple_lights[4 * k_maximum_simple_light_count], c16);

DECLARE_PARAMETER(float4, vs_antialias_scalars, c250);						//
DECLARE_PARAMETER(float4, vs_object_velocity, c251);							// velocity of the current object, world space per object (approx)	###ctchou $TODO we could compute this in the vertex shader as a function of the bones...

DECLARE_PARAMETER(float3, contrast, c13);

// per block/instance/decorator_set
DECLARE_PARAMETER(float4, instance_compression_offset, c240);
DECLARE_PARAMETER(float4, instance_compression_scale, c241);
// Instance data holds the index count of one instance, as well as an index offset
// for drawing index buffer subsets.
DECLARE_PARAMETER(float4, instance_data, c242);

#ifdef DECORATOR_DYNAMIC_LIGHTS
DECLARE_PARAMETER(float4, translucency, c243);
#endif

#ifdef DECORATOR_WAVY
// depends on type
DECLARE_PARAMETER(float4, wave_flow, c249);		// phase direction + frequency
#endif

#if !defined(xenon)

DECLARE_PARAMETER(float4,		pc_ambient_light,	c176);
DECLARE_PARAMETER(float4,		selection_point,	c177);
DECLARE_PARAMETER(float4,		selection_curve,	c178);
DECLARE_PARAMETER(float4,		selection_color,	c179);
DECLARE_PARAMETER(float4, instance_position_and_scale, c17);
DECLARE_PARAMETER(float4, instance_quaternion, c18);

#endif

#elif DX_VERSION == 11

CBUFFER_BEGIN(DecoratorsVS)
	CBUFFER_CONST(DecoratorsVS,			int,		v_simple_light_count,									k_vs_decorators_int_simple_light_count)
	CBUFFER_CONST(DecoratorsVS,			int3,		v_simple_light_count_pad,								k_vs_decorators_simple_light_count_pad)
	CBUFFER_CONST_ARRAY(DecoratorsVS,	float4, 	v_simple_lights, [5 * k_maximum_simple_light_count], 	k_vs_decorators_simple_lights)
	CBUFFER_CONST(DecoratorsVS,			float4, 	vs_antialias_scalars, 									k_vs_decorators_antialias_scalars)
	CBUFFER_CONST(DecoratorsVS,			float4, 	vs_object_velocity, 									k_vs_decorators_object_velocity)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsInstanceVS)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	instance_compression_offset,							k_vs_decorators_instance_compression_offset)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	instance_compression_scale,								k_vs_decorators_instance_compression_scale)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	instance_data,											k_vs_decorators_instance_data)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	translucency,											k_vs_decorators_translucency)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	wave_flow,												k_vs_decorators_wave_flow)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	instance_position_and_scale,							k_vs_decorators_instance_position_and_scale)
	CBUFFER_CONST(DecoratorsInstanceVS,	float4, 	instance_quaternion,									k_vs_decorators_instance_quaternion)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsPS)
	CBUFFER_CONST(DecoratorsPS,			float3, 	contrast, 												k_ps_decorators_contrast)
	CBUFFER_CONST(DecoratorsPS,			float,	 	contrast_pad, 											k_ps_decorators_contrast_pad)
	CBUFFER_CONST(DecoratorsPS,			float4,		pc_ambient_light,										k_ps_decorators_pc_ambient_light)
	CBUFFER_CONST(DecoratorsPS,			float4,		selection_point,										k_ps_decorators_selection_point)
	CBUFFER_CONST(DecoratorsPS,			float4,		selection_curve,										k_ps_decorators_selection_curve)
	CBUFFER_CONST(DecoratorsPS,			float4,		selection_color,										k_ps_decorators_selection_color)
CBUFFER_END

#endif
