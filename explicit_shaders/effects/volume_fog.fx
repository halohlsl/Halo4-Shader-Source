#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME
#define DISABLE_VIEW_VECTOR
#define DISABLE_VERTEX_COLOR

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "deform.fxh"
#include "volume_fog_registers.fxh"

#define NEAREST_DEPTH vs_projectionScaleOffset.x

//DECLARE_PARAMETER(float4, ps_fogColor_fogIntensity, c3) = float4(0.5, 0.5, 0.5, 0.2);
#define ps_fogColor_fogIntensity	ps_material_object_parameters[0]
#define ps_projectionScaleOffset	ps_material_generic_parameters[0]


// Texture Samplers
DECLARE_SAMPLER(noise_map, "Noise Map", "Noise Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

// Texture controls
DECLARE_FLOAT_WITH_DEFAULT(noise_intensity,			"Noise Intensity", "", 0, 1, float(0.01));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(distance_scale,			"Distance Scale", "", 0, 1, float(0.03));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fog_thickness,			"Fog Thickness", "", 0, 5, float(0.1));
#include "used_float.fxh"

////////////////////////////////////////////////////////////////////////////////
/// Volume fog pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#define BUILD_VOLUME_FOG_VS(vertex_type)										\
void volume_fog_stencil_##vertex_type##_vs(										\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out float4 surfaceDepth : TEXCOORD0,										\
	out float4 texcoord: TEXCOORD1)												\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	output= (s_vertex_shader_output)0;											\
	float4 local_to_world_transform[3];											\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);\
	texcoord.xyzw = input.texcoord.xyxy;										\
	surfaceDepth.zw = out_position.zw;											\
	surfaceDepth.xy = vs_projectionScaleOffset.zw;								\
}

// Build vertex shaders for the volume fog pass
BUILD_VOLUME_FOG_VS(world);									// volume_fog_stencil_world_vs
BUILD_VOLUME_FOG_VS(rigid);									// volume_fog_stencil_rigid_vs
BUILD_VOLUME_FOG_VS(skinned);								// volume_fog_stencil_skinned_vs
BUILD_VOLUME_FOG_VS(rigid_boned);							// volume_fog_stencil_rigid_boned_vs
BUILD_VOLUME_FOG_VS(rigid_blendshaped);						// volume_fog_stencil_rigid_blendshaped_vs
BUILD_VOLUME_FOG_VS(skinned_blendshaped);					// volume_fog_stencil_skinned_blendshaped_vs

// Use the same vertex shaders for the depth pass
#define volume_fog_depth_world_vs							volume_fog_stencil_world_vs
#define volume_fog_depth_rigid_vs							volume_fog_stencil_rigid_vs
#define volume_fog_depth_skinned_vs							volume_fog_stencil_skinned_vs
#define volume_fog_depth_rigid_boned_vs						volume_fog_stencil_rigid_boned_vs
#define volume_fog_depth_rigid_blendshaped_vs				volume_fog_stencil_rigid_blendshaped_vs
#define volume_fog_depth_skinned_blendshaped_vs				volume_fog_stencil_skinned_blendshaped_vs



////////////////////////////////////////////////////////////////////////////////
/// Volume fog pass pixel shaders
////////////////////////////////////////////////////////////////////////////////


float4 volume_fog_stencil_default_ps() : SV_Target0
{
	return 0.25 * ps_exposure.xxxx;
}

float4 volume_fog_depth_default_ps(
	in float4 screenPosition : SV_Position,
	in float4 surfaceDepth : TEXCOORD0,
	in float4 texcoord : TEXCOORD1
#if defined(xenon)
	, in float faceDirection : VFACE
#elif DX_VERSION == 11
	, in bool isFrontFace : SV_IsFrontFace
#endif
) : SV_Target0
{
#if defined(xenon) || (DX_VERSION == 11)
	float depth = surfaceDepth.z / surfaceDepth.w;
	surfaceDepth.x = 1.0f / (surfaceDepth.x + depth * surfaceDepth.y) - ps_projectionScaleOffset.x;
	surfaceDepth.yzw = 0.0f;

	float2 noise_map_uv = transform_texcoord(texcoord, noise_map_transform);
	float4 noiseSample = sample2D(noise_map, noise_map_uv);

#ifdef xenon
	if (faceDirection < 0.0f)
#else
	if (isFrontFace)
#endif
	{
		surfaceDepth.x += noise_intensity * (noiseSample.r * 2 - 1);
		return surfaceDepth.xyzw * distance_scale;
	}
	else
	{
		surfaceDepth.x += noise_intensity * (noiseSample.g * 2 - 1);
		return surfaceDepth.yxzw * distance_scale;
	}
#else
	return surfaceDepth;
#endif
}

#if !defined(cgfx)


// Mark this shader as volume fog
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_volume_fog = true;>

#include "techniques_base.fxh"

MAKE_TECHNIQUE(volume_fog_stencil)
MAKE_TECHNIQUE(volume_fog_depth)


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex apply_volume_fog_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position.xy=	input.position;
	output.position.zw=	float2(NEAREST_DEPTH, 1.0f);
	output.texcoord=	input.texcoord.xyxy;
	return output;
}

float4 apply_volume_fog_ps(const in s_vertex_output_screen_tex input) : SV_Target
{
	float4 source = sample2D(fog_volume_sampler, input.texcoord);

	float fogDistance = saturate(source.r - source.g);
	float alpha = ps_fogColor_fogIntensity.a * fogDistance;

	return float4(ps_fogColor_fogIntensity.rgb, alpha);
}




BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(apply_volume_fog_vs());
		SET_PIXEL_SHADER(apply_volume_fog_ps());
	}
}



s_vertex_output_screen_tex correct_fog_depth_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position = float4(input.position.xy, 1.0, 1.0);
	output.texcoord.xy = input.texcoord;
	output.texcoord.zw = vs_projectionScaleOffset.zw;
	return output;
}

float4 correct_fog_depth_ps(const in s_vertex_output_screen_tex input) : SV_Target
{
	float source = sample2D(depth_sampler, input.texcoord.xy).x;

	source = 1.0f / (input.texcoord.z + source * input.texcoord.w) - ps_projectionScaleOffset.x;

	return source.xxxx * distance_scale; // test
}



BEGIN_TECHNIQUE shadow_generate
{
	pass screen
	{
		SET_VERTEX_SHADER(correct_fog_depth_vs());
		SET_PIXEL_SHADER(correct_fog_depth_ps());
	}
}




#else


struct s_shader_data {
	s_common_shader_data common;

};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
}

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	return float4(0.5,0.5,0.5,0.5);
}


#include "techniques_cgfx.fxh"

#endif
