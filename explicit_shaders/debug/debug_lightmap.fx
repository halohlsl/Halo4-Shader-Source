#include "core/core.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

#include "entrypoints/common.fxh"
#include "debug_registers.fxh"


// pixel 

// debug_color:
// .rgb - debug color
// .a   - mode for debug rendering:
//	  0 - lightmap UV display
//	  1 - AO display

// vmf.fxh
float SamplePerPixelAO(in float2 uv)
{
	float4 shData = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float3 uv3 = float3(uv, 0.0f);
	
#if defined(xenon) && !defined(DISABLE_VMF)
	asm{ tfetch2D shData.zw__, uv3, ps_bsp_lightprobe_analytic, MipFilter=point,MinFilter=linear,MagFilter=linear };
#endif

	return shData.y;
}

float SamplePerVertexAO(int vertexIndex, uniform bool aoOnly)
{
	int3 unnormTexcoord = 0;
	int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;
	unnormTexcoord.x = offsetVertexIndex % 1024;
	unnormTexcoord.y = offsetVertexIndex / 1024;
		
	float shData = 0.5f;

#if defined(xenon) && !defined(DISABLE_VMF)	
	if (aoOnly)
	{
		asm{ tfetch3D shData.z___, unnormTexcoord, vs_bsp_lightprobe_ao_data, OffsetZ = 0.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
	}
	else
	{
		asm{ tfetch3D shData.y___, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 2.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
	}
#endif

	return shData;
}

#define DEBUG_VS(vertextype_name)\
void debug_##vertextype_name##_vs(\
	in s_##vertextype_name##_vertex input,\
	in uint vertexIndex : SV_VertexID,\
	in s_lightmap_per_pixel input_lightmap,\
	uniform bool perPixel,\
	uniform bool aoOnly,\
	ISOLATE_OUTPUT out float4 out_position: SV_Position,\
	out float3 vsData : TEXCOORD0)\
{\
	s_vertex_shader_output output = (s_vertex_shader_output)0;\
	float4 local_to_world_transform[3];\
	apply_transform(deform_##vertextype_name, input, output, local_to_world_transform, out_position);\
	vsData = float3(input_lightmap.texcoord.xy, 0);\
	if (!perPixel)\
	{\
		vsData.z = SamplePerVertexAO(vertexIndex, aoOnly);\
	}\
}\

DEBUG_VS(world)
DEBUG_VS(rigid)
DEBUG_VS(skinned)
DEBUG_VS(rigid_boned)

float4 debug_default_ps(
	uniform bool perPixel, 
	uniform bool isForge, 
	uniform bool aoOnly, 
	in float4 screenPosition : SV_Position,
	in float3 vsData : TEXCOORD0) : SV_Target
{
	float3 color = float3(1,1,1);
	
	if (debug_color.a < 1)
	{
		// ps_bsp_lightmap_compress_constant_2.z == lightmap texture width
		float2 integer_coords;
		if (isForge)
		{
			integer_coords = floor(vsData.xy * ps_forge_lightmap_compress_constant.y);
		}
		else
		{
			integer_coords = floor(vsData.xy * ps_bsp_lightmap_compress_constant_2.z);
		}
			
		
		int xm = ((int)integer_coords.x) % 2;
		int ym = ((int)integer_coords.y) % 2;

		if ((xm == 0 && ym == 0) || (xm == 1 && ym == 1))
		{
			color = float3(0.5f, 0.5f, 0.5f);
		}
		else
		{
			color = float3(0.0f, 0.0f, 0.0f);
		}
	}
	else if (debug_color.a < 2)
	{
		if (perPixel)
		{
			color = SamplePerPixelAO(vsData.xy);
		}
		else
		{
			color = vsData.z;
		}
	}
	
	return float4(color, ps_view_exposure.w);
}


#define MAKE_DEFAULT_PASS(entrypoint_name, perPixel, isForge, aoOnly)\
	pass _default\
	{\
		SET_PIXEL_SHADER(entrypoint_name##_default_ps(perPixel, isForge, aoOnly));\
	}

#define MAKE_PASS(entrypoint_name, vertextype_name, perPixel, isForge, aoOnly)\
	pass vertextype_name\
	{\
		SET_VERTEX_SHADER(entrypoint_name##_##vertextype_name##_vs(perPixel, aoOnly));\
	}

#define MAKE_TECHNIQUE(entrypoint_name, staticTechnique, perPixel, isForge, aoOnly)\
	BEGIN_TECHNIQUE staticTechnique \
	{\
		MAKE_DEFAULT_PASS(entrypoint_name, perPixel, isForge, aoOnly)\
		MAKE_PASS(entrypoint_name, world, perPixel, isForge, aoOnly)\
		MAKE_PASS(entrypoint_name, rigid, perPixel, isForge, aoOnly)\
		MAKE_PASS(entrypoint_name, skinned, perPixel, isForge, aoOnly)\
		MAKE_PASS(entrypoint_name, rigid_boned, perPixel, isForge, aoOnly)\
	}

MAKE_TECHNIQUE(debug, static_per_vertex, false, false, false)
MAKE_TECHNIQUE(debug, static_per_pixel, true, false, false)
MAKE_TECHNIQUE(debug, static_per_pixel_forge, true, true, false)
MAKE_TECHNIQUE(debug, static_per_vertex_ao, false, false, true)
