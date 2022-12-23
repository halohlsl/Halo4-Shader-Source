#if DX_VERSION == 9

DECLARE_PARAMETER(float3, vs_position, c33);
DECLARE_PARAMETER(float3, vs_direction, c34);
DECLARE_PARAMETER(float4, vs_color, c35);
DECLARE_PARAMETER(float2, vs_size, c36);
DECLARE_PARAMETER(float2, vs_angleFadeRangeCutoff, c37);

#elif DX_VERSION == 11

CBUFFER_BEGIN(LightConeVS)
	CBUFFER_CONST(LightConeVS,		float3, 	vs_position, 					k_vs_light_cone_position)
	CBUFFER_CONST(LightConeVS,		float, 		vs_position_pad, 				k_vs_light_cone_position_pad)
	CBUFFER_CONST(LightConeVS,		float3, 	vs_direction, 					k_vs_light_cone_direction)
	CBUFFER_CONST(LightConeVS,		float,	 	vs_direction_pad, 				k_vs_light_cone_direction_pad)
	CBUFFER_CONST(LightConeVS,		float4, 	vs_color, 						k_vs_light_cone_color)
	CBUFFER_CONST(LightConeVS,		float2, 	vs_size, 						k_vs_light_cone_size)
	CBUFFER_CONST(LightConeVS,		float2, 	vs_size_pad, 					k_vs_light_cone_size_pad)
	CBUFFER_CONST(LightConeVS,		float2, 	vs_angleFadeRangeCutoff, 		k_vs_light_cone_angle_fade_range_cutoff)
	CBUFFER_CONST(LightConeVS,		float2, 	vs_angleFadeRangeCutoff_pad, 	k_vs_light_cone_angle_fade_range_cutoff_pad)
CBUFFER_END

#endif
