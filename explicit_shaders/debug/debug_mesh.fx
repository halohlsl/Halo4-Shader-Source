#include "core/core.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

#include "entrypoints/common.fxh"
#include "debug_registers.fxh"


// pixel

// debug_color
// .rgb - debug color
// .a   - mode for debug rendering:
//	  0 - output just the debug color
//	  1 - output checkerboard based upon uv0
//	  2,3,4,5,6,7 - mip display

LOCAL_SAMPLER2D(tex_sampler, 0);

void deform_debug_world(
	inout s_world_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	vertex.position.xyz= vertex.position.xyz*vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;
	vertex.position.w= 1.0f;
	vertex.texcoord= vertex.texcoord*vs_mesh_uv_compression_scale_offset.xy + vs_mesh_uv_compression_scale_offset.zw;

	vertex.normal.xyz= normalize(transform_vector(vertex.normal.xyz, local_to_world_transform));
	vertex.tangent.xyz= normalize(transform_vector(vertex.tangent.xyz, local_to_world_transform));
}

void deform_debug_rigid(
	inout s_rigid_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	vertex.position.xyz= vertex.position.xyz*vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;
	vertex.position.w= 1.0f;
	vertex.texcoord= vertex.texcoord*vs_mesh_uv_compression_scale_offset.xy + vs_mesh_uv_compression_scale_offset.zw;

	vertex.normal.xyz= normalize(transform_vector(vertex.normal.xyz, local_to_world_transform));
	vertex.tangent.xyz= normalize(transform_vector(vertex.tangent.xyz, local_to_world_transform));
}

void deform_debug_skinned(
	inout s_skinned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	// normalize the node weights so that they sum to 1
	float sum_of_weights = dot(vertex.node_weights.xyzw, 1.0f);
	vertex.node_weights = vertex.node_weights/sum_of_weights;

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	BlendSkinningMatrices(local_to_world_transform, vertex.node_indices, vertex.node_weights, 4);

	vertex.normal.xyz= normalize(transform_vector(vertex.normal.xyz, local_to_world_transform));
	vertex.tangent.xyz= normalize(transform_vector(vertex.tangent.xyz, local_to_world_transform));
}


void debug_world_vs(
	in s_world_vertex input,
	in s_lightmap_per_pixel input_lightmap,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float4 texcoord : TEXCOORD0)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_debug_world, input, output, local_to_world_transform, out_position);
	texcoord.xy = input.texcoord.xy;
	texcoord.zw = input_lightmap.texcoord.xy;
}

void debug_rigid_vs(
	in s_rigid_vertex input,
	in s_lightmap_per_pixel input_lightmap,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float4 texcoord : TEXCOORD0)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_debug_rigid, input, output, local_to_world_transform, out_position);
	texcoord.xy = input.texcoord.xy;
	texcoord.zw = input_lightmap.texcoord.xy;
}

void debug_skinned_vs(
	in s_skinned_vertex input,
	in s_lightmap_per_pixel input_lightmap,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float4 texcoord : TEXCOORD0)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_debug_skinned, input, output, local_to_world_transform, out_position);
	texcoord.xy = input.texcoord.xy;
	texcoord.zw = input_lightmap.texcoord.xy;
}



float4 debug_default_ps(in float4 uv : TEXCOORD0) : SV_Target
{
	float3 color = float3(1,1,1);

	if (debug_color.a < 1)
	{
		color = debug_color.rgb;
	}
	else if (debug_color.a < 2)
	{
		float factor = 4;
		float2 checker = frac(uv.xy*factor);
		if ((checker.x<0.5 && checker.y<0.5) || (checker.x>=0.5 && checker.y>=0.5))
			color *= 1;
		else
			color *= 0.80;

		float4 intensity = float4(frac(uv.xy)*0.9+0.1, 0, 1);
		color *= intensity;
	}
	else if (debug_color.a < 8)
	{
#ifdef xenon
		float4 lod;
		uv.xy = transform_texcoord(uv.xy,debug_mesh_xform);
		asm {
			getCompTexLOD2D lod, uv.xy, tex_sampler
		};

		float3 table[] = {
			float3(  1,  0,  0),
			float3(  1,0.5,  0),
			float3(  1,  1,  0),
			float3(0.5,  1,  0),
			float3(  0,  1,  0),
			float3(  0,  1,0.5),
			float3(  0,  1,  1),
			float3(  0,0.5,  1),
			float3(  0,  0,  1),
			float3(  0,  0,  1)
		};

		float index = clamp(lod.x, debug_mesh_misc.x, 8);
		float d = frac(index);
		float3 color1 = table[index];
		float3 color2 = table[index+1];
		color = lerp(color1, color2, d);
#endif
	}
	return float4(color, ps_view_exposure.w);
}


#define MAKE_DEFAULT_PASS(entrypoint_name)\
	pass _default\
	{\
		SET_PIXEL_SHADER(entrypoint_name##_default_ps());\
	}

#define MAKE_PASS(entrypoint_name, vertextype_name)\
	pass vertextype_name\
	{\
		SET_VERTEX_SHADER(entrypoint_name##_##vertextype_name##_vs());\
	}

#define MAKE_NAMED_TECHNIQUE(entrypoint_name, technique_name)\
	BEGIN_TECHNIQUE technique_name\
	{\
		MAKE_DEFAULT_PASS(entrypoint_name)\
		MAKE_PASS(entrypoint_name, world)\
		MAKE_PASS(entrypoint_name, rigid)\
		MAKE_PASS(entrypoint_name, skinned)\
	}

MAKE_NAMED_TECHNIQUE(debug, _default)
MAKE_NAMED_TECHNIQUE(debug, lightmap_debug_mode)
