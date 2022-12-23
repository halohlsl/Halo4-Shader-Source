#if defined(PROCEDURAL_UV)
#define DISABLE_TANGENT_FRAME
#define DISABLE_VERTEX_COLOR
#define DISABLE_SHADOW_FRUSTUM_POS
#endif

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "deform.fxh"
#include "exposure.fxh"

// we'll handle the depth fade range on our own, using Bungie's "inverse_range"
#define DEPTH_FADE_RANGE 1
#define DEPTH_FADE_INVERT false

#include "depth_fade.fxh"
#include "shield_impact_registers.fxh"


float2 compute_depth_fade2(float2 screen_coords, float depth, float2 inverse_range)
{
	return saturate(ComputeDepthFade(screen_coords, depth) * inverse_range);
}


#define EXTRUSION_DISTANCE		(vertex_params.x)
#define OSCILLATION_AMPLITUDE	(vertex_params.z)
#define OSCILLATION_SCALE		(vertex_params.w)
#define OSCILLATION_OFFSET0		(vertex_params2.xy)
#define OSCILLATION_OFFSET1		(vertex_params2.zw)

void ShieldImpactVS(
	in float3 position,
	in float3 normal,
#if !defined(PROCEDURAL_UV)
	in float2 texcoord,
#endif
	out float4 shieldImpactWorldPos,
	out float4 shieldImpactTexcoord,
	out float4 shieldProjectedPos)
{
#if defined(xenon) || (DX_VERSION == 11)
	float3	impact_delta =				position -	impact0_params.xyz;
	float	impact_distance =			length(impact_delta) /	impact0_params.w;

	float3	world_position =			position.xyz + normal * EXTRUSION_DISTANCE;

	float noise_value1=			sample2DLOD(vs_shield_impact_noise_texture1, world_position.xy * OSCILLATION_SCALE + OSCILLATION_OFFSET0, 0.0f, false);
	float noise_value2=			sample2DLOD(vs_shield_impact_noise_texture2, world_position.yz * OSCILLATION_SCALE + OSCILLATION_OFFSET1, 0.0f, false);

	float noise=				(noise_value1 + noise_value2 - 1.0f) * OSCILLATION_AMPLITUDE;

	world_position		+=		normal * noise;

	float3 camera_to_vertex=	world_position - vs_view_camera_position.xyz;

	float cosine_view=		-dot(normalize(camera_to_vertex), normal);
	shieldImpactWorldPos =		float4(world_position, cosine_view);

	float depth=			-dot(camera_to_vertex, vs_view_camera_backward.xyz);

#if defined(PROCEDURAL_UV)
	float2 texcoord;
	float3 normalizedVector = float3(1, 1, 1);//abs(normalize(vertex_in.position));
	texcoord.x = position.y * normalizedVector.x;
	texcoord.y = position.z * normalizedVector.x;

	texcoord.x += position.x * normalizedVector.y;
	texcoord.y += position.z * normalizedVector.y;

	texcoord.x += position.x * normalizedVector.z;
	texcoord.y += position.y * normalizedVector.z;
#endif // PROCEDURAL_UV
	shieldProjectedPos=			mul(float4(world_position, 1.0f), vs_view_view_projection_matrix);
	shieldImpactTexcoord.xy=	texcoord.xy;
	shieldImpactTexcoord.z=		depth;
	shieldImpactTexcoord.w=		impact_distance;
#else
	shieldImpactWorldPos = 0;
	shieldImpactTexcoord = 0;
	shieldProjectedPos = 0;
#endif
}





////////////////////////////////////////////////////////////////////////////////
/// Active camo pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#if defined(PROCEDURAL_UV)

struct s_imposter_interpolators
{
	float4 position			:SV_Position0;
	float3 normal			:NORMAL0;
	float3 diffuse			:COLOR0;
	float3 ambient			:COLOR1;
	float4 specular_shininess		:COLOR2;
	float4 change_colors_of_diffuse		:TEXCOORD0;
	float4 change_colors_of_specular	:TEXCOORD1;
	float3 view_vector		:TEXCOORD2;
};

void shield_impact_object_imposter_vs(
	in s_object_imposter_vertex input,
	ISOLATE_OUTPUT out float4 out_position : SV_Position,
	out float4 shieldImpactWorldPos : TEXCOORD0,
	out float4 shieldImpactTexcoord : TEXCOORD1)
{
	s_imposter_interpolators output = (s_imposter_interpolators)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_object_imposter, input, output, local_to_world_transform, output.position);
	ShieldImpactVS(input.position, output.normal, shieldImpactWorldPos, shieldImpactTexcoord, out_position);
}

#else // PROCEDURAL_UV

#define BUILD_SHIELD_IMPACT_VS(vertex_type)										\
void shield_impact_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out float4 shieldImpactWorldPos : TEXCOORD0,								\
	out float4 shieldImpactTexcoord : TEXCOORD1)								\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	output= (s_vertex_shader_output)0;											\
	float4 local_to_world_transform[3];											\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);\
	output.texcoord= input.texcoord.xyxy;										\
	ShieldImpactVS(input.position, output.normal, input.texcoord.xy, shieldImpactWorldPos, shieldImpactTexcoord, out_position);\
}

// Build vertex shaders for the active camo pass
BUILD_SHIELD_IMPACT_VS(world);								// shield_impact_world_vs
BUILD_SHIELD_IMPACT_VS(rigid);								// shield_impact_rigid_vs
BUILD_SHIELD_IMPACT_VS(skinned);							// shield_impact_skinned_vs
BUILD_SHIELD_IMPACT_VS(rigid_boned);						// shield_impact_rigid_boned_vs
BUILD_SHIELD_IMPACT_VS(rigid_blendshaped);					// shield_impact_rigid_blendshaped_vs
BUILD_SHIELD_IMPACT_VS(skinned_blendshaped);				// shield_impact_skinned_blendshaped_vs

#endif // PROCEDURAL_UV




#define OUTER_SCALE			(edge_scales.x)
#define INNER_SCALE			(edge_scales.y)
#define OUTER_SCALE2		(edge_scales.z)
#define INNER_SCALE2		(edge_scales.w)

#define OUTER_OFFSET		(edge_offsets.x)
#define INNER_OFFSET		(edge_offsets.y)
#define OUTER_OFFSET2		(edge_offsets.z)
#define INNER_OFFSET2		(edge_offsets.w)

#define PLASMA_TILE_SCALE1	(plasma_scales.x)
#define PLASMA_TILE_SCALE2	(plasma_scales.y)

#define PLASMA_TILE_OFFSET1	(plasma_offsets.xy)
#define PLASMA_TILE_OFFSET2	(plasma_offsets.zw)

#define PLASMA_POWER_SCALE	(plasma_scales.z)
#define PLASMA_POWER_OFFSET	(plasma_scales.w)

#define EDGE_GLOW_COLOR		(edge_glow.rgba)
#define PLASMA_COLOR		(plasma_color.rgba)
#define PLASMA_EDGE_COLOR	(plasma_edge_color.rgba)

#define INVERSE_DEPTH_FADE_RANGE	(depth_fade_params.xy)


[maxtempreg(5)]
float4 shield_impact_default_ps(
	in SCREEN_POSITION_INPUT(vpos),
	//in float4 position				: POSITION,
	in float4 world_space_pos		: TEXCOORD0,
	in float4 texcoord				: TEXCOORD1,
	uniform bool texturedHit) : SV_Target0
{
#if defined(xenon) || (DX_VERSION == 11)
	float edge_fade=			world_space_pos.w;
	float depth=				texcoord.z;

	float2 depth_fades=			compute_depth_fade2(vpos, depth, INVERSE_DEPTH_FADE_RANGE);

	float	edge_linear=		saturate(min(edge_fade * OUTER_SCALE + OUTER_OFFSET, edge_fade * INNER_SCALE + INNER_OFFSET));
	float	edge_plasma_linear=	saturate(min(edge_fade * OUTER_SCALE2 + OUTER_OFFSET2, edge_fade * INNER_SCALE2 + INNER_OFFSET2));
	float	edge_quartic=		pow(edge_linear, 4);
	float	edge=				edge_quartic * depth_fades.x;
	float	edge_plasma=		edge_plasma_linear * depth_fades.y;

	float	plasma_noise1=		sample2D(shield_impact_noise_texture1, texcoord.xy * PLASMA_TILE_SCALE1 + PLASMA_TILE_OFFSET1);
	float	plasma_noise2=		sample2D(shield_impact_noise_texture2, texcoord.xy * PLASMA_TILE_SCALE2 - PLASMA_TILE_OFFSET2);		// Do not change the '-' ...   it makes it compile magically (yay for the xbox shader compiler)
	float	plasma_base=		saturate(1.0f - abs(plasma_noise1 - plasma_noise2));
	float	plasma_power=		edge_plasma * PLASMA_POWER_SCALE + PLASMA_POWER_OFFSET;
	float	plasma=				pow(plasma_base, plasma_power);

	float4	hit_color=			impact0_color * saturate(1.0f - texcoord.w);
	
	if (texturedHit)
	{
		hit_color *= sample2D(hitBlobTexture, float2(texcoord.xw)); // using x to save registers; only actually care about w
	}

	float4	final_color=		edge * EDGE_GLOW_COLOR + (PLASMA_EDGE_COLOR * edge_plasma + PLASMA_COLOR + hit_color) * plasma;

#else // pc
	float4	final_color=		0.0f;
#endif // xenon

	return ApplyExposureScaleSelfIllum(final_color, GetLinearColorIntensity(final_color));
}

#if !defined(cgfx)
// I thought I might need this (supporting texturedHit in VS), and may in fact in the future, so I'll leave it
#define MAKE_VERTEX_PASS(vertextype_name, texturedHit)\
	pass vertextype_name\
	{\
		SET_VERTEX_SHADER(shield_impact_##vertextype_name##_vs());\
	}

#if defined(PROCEDURAL_UV)
#define MAKE_SHIELD_TECHNIQUE(texturedHit) \
BEGIN_TECHNIQUE \
{\
	pass _default { SET_PIXEL_SHADER(shield_impact_default_ps(texturedHit)); }\
	MAKE_VERTEX_PASS(object_imposter, texturedHit)\
}
#else // PROCEDURAL_UV
#define MAKE_SHIELD_TECHNIQUE(texturedHit) \
BEGIN_TECHNIQUE \
{\
	pass _default { SET_PIXEL_SHADER(shield_impact_default_ps(texturedHit)); }\
	MAKE_VERTEX_PASS(world, texturedHit)\
	MAKE_VERTEX_PASS(rigid, texturedHit)\
	MAKE_VERTEX_PASS(skinned, texturedHit)\
	MAKE_VERTEX_PASS(rigid_boned, texturedHit)\
	MAKE_VERTEX_PASS(rigid_blendshaped, texturedHit)\
	MAKE_VERTEX_PASS(skinned_blendshaped, texturedHit)\
}
#endif // PROCEDURAL_UV

MAKE_SHIELD_TECHNIQUE(false) // entry point 0
MAKE_SHIELD_TECHNIQUE(true) // entry point 1
#endif // !defined(cgfx)
