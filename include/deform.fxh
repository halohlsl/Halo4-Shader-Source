#if !defined(__DEFORM_FXH)
#define __DEFORM_FXH

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"


#if !defined(custom_deformer)
#define custom_deformer(vertex, vertexColor, local_to_world)
#endif

#define world_projection_transform(vertex, local_to_world, out_position)						\
	ISOLATE {vertex.position= float4(transform_point(vertex.position, local_to_world_transform), 1.0f);	\
	out_position= mul(vertex.position, vs_view_view_projection_matrix);}

/*
// aluedke (11/14/2011): Shader tweak to composite matrices before multiply to improve precision at large offsets from origin. Not tested.
#define world_projection_transform(vertex, local_to_world, out_position)						\
	{float4x4 fullTransform = float4x4(local_to_world[0], local_to_world[1], local_to_world[2], float4(0,0,0,1));\
	fullTransform = mul(fullTransform, vs_view_view_projection_matrix);\
	out_position = mul(vertex.position, fullTransform);}
*/

#if !defined(cgfx)
#define output_binormal(vertex, output)															\
	output.binormal.xyz= generate_binormal(output.normal.xyz, output.tangent.xyz, vertex.tangent.w)
#define transform_binormal(vertex, local_to_world)
#else
#define output_binormal(vertex, output)															\
	output.binormal.xyz= vertex.binormal
#define transform_binormal(vertex, local_to_world)												\
	vertex.binormal.xyz = normalize(transform_vector(vertex.binormal.xyz, local_to_world))
#endif

#if !defined(DISABLE_TANGENT_FRAME)
#define transform_tangent_frame(vertex, local_to_world)											\
	vertex.normal.xyz = normalize(transform_vector(vertex.normal.xyz, local_to_world));			\
	vertex.tangent.xyz = normalize(transform_vector(vertex.tangent.xyz, local_to_world));		\
	transform_binormal(vertex, local_to_world)
#elif !defined(DISABLE_NORMAL)
#define transform_tangent_frame(vertex, local_to_world)											\
	vertex.normal.xyz = normalize(transform_vector(vertex.normal.xyz, local_to_world))
#else
#define transform_tangent_frame(vertex, local_to_world)
#endif


#if !defined(DISABLE_TANGENT_FRAME)
#define output_tangent_frame(vertex, output)													\
	output.normal.xyz= vertex.normal;															\
	output.tangent.xyz= vertex.tangent;															\
	output_binormal(vertex, output)
#elif !defined(DISABLE_NORMAL)
#define output_tangent_frame(vertex, output)													\
	output.normal.xyz= vertex.normal
#else
#define output_tangent_frame(vertex, output)
#endif

#if !defined(DISABLE_VIEW_VECTOR)
#define output_view_vector(vertex, output)														\
	output.view_vector.xyz = vertex.position.xyz - vs_view_camera_position.xyz;
#else
#define output_view_vector(vertex, output)
#endif

#if !defined(DISABLE_VERTEX_COLOR)
#if defined(cgfx)
#define OutputVertexColor(vertex, output, vcolor)												\
	output.vertexColor = float4(vertex.vertexColor.r, vertex.vertexColor.g, vertex.vertexColor.b, vertex.vertexColor.r)
#elif defined(FULL_VERTEX_COLOR)
#define OutputVertexColor(vertex, output, vcolor)												\
	output.vertexColor = vcolor
#elif !defined(DISABLE_NORMAL)
#define OutputVertexColor(vertex, output, vcolor)												\
	output.normal.w = vcolor.a
#elif !defined(DISABLE_VIEW_VECTOR)
#define OutputVertexColor(vertex, output, vcolor)												\
	output.view_vector.w = vcolor.a
#endif
#else
#define OutputVertexColor(vertex, output, vcolor)
#endif

#if defined(ENABLE_DEPTH_INTERPOLATER)
#define OutputVertexDepth(vertex, output)												\
	output.view_vector.w = dot(vs_view_camera_backward, vs_view_camera_position - vertex.position.xyz)
#else
#define OutputVertexDepth(vertex, output)
#endif

#if (defined(xenon) || (DX_VERSION==11)) && !defined(DISABLE_SHADOW_FRUSTUM_POS)
#define OutputShadowFrustumPos(vertex, output)													\
	output.shadowProjection = CalculateFloatingShadowFrustumSpacePosition(vertex.position.xyz)
#else
#define OutputShadowFrustumPos(vertex, output)
#endif

#define apply_transform(deformer, vertex, output, local_to_world, out_position)					\
	{																							\
		float4 vertexColor = float4(1,1,1,vertex.position.w);									\
		transform_identity(local_to_world);														\
		deformer(vertex, vertexColor, local_to_world);											\
		custom_deformer(vertex, vertexColor, local_to_world);									\
		world_projection_transform(vertex, local_to_world, out_position);						\
		transform_tangent_frame(vertex, local_to_world);										\
		output_tangent_frame(vertex, output);													\
		output_view_vector(vertex, output);														\
		OutputVertexColor(vertex, output, vertexColor);											\
		OutputVertexDepth(vertex, output);														\
		OutputShadowFrustumPos(vertex, output);													\
	}

#define apply_transform_position_only(deformer, vertex, output, local_to_world, out_position)	\
	{																							\
		float4 vertexColor = float4(1,1,1,1);													\
		transform_identity(local_to_world);														\
		deformer(vertex, vertexColor, local_to_world);											\
		custom_deformer(vertex, vertexColor, local_to_world);									\
		world_projection_transform(vertex, local_to_world, out_position);						\
	}

// Copies the matrix
void CopyMatrix(out float4 targetMatrix[3], in float4 sourceMatrix[3])
{
	for (int i = 0; i < 3; ++i)
	{
		targetMatrix[i] = sourceMatrix[i];
	}
}

// Scales and adds a matrix into the target
void AddMatrix(inout float4 targetMatrix[3], in float4 sourceMatrix[3], in float scale)
{
	for (int i = 0; i < 3; ++i)
	{
		targetMatrix[i] += sourceMatrix[i] * scale;
	}
}

// Many positions are compressed into 16-bit normalized integers and must be decompressed
void DecompressPosition(inout float4 position)
{
	position.xyz = position.xyz * vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;
	position.w = 1.0f;
}

// Many texcoords are compressed into 16-bit normalized integers and must be decompressed
void DecompressTexcoord(inout float2 texcoord)
{
	texcoord = texcoord * vs_mesh_uv_compression_scale_offset.xy + vs_mesh_uv_compression_scale_offset.zw;
}

// Skinning matrices are compressed into 16-bit normalized integers and must be decompressed
void DecompressSkinningMatrix(inout float4 targetMatrix[3], uniform bool previous = false)
{
#if !defined(EXCLUDE_MODEL_MATRICES) && defined(USE_VERTEX_STREAM_SKINNING)

	// The rotational portion of the matrices are compressed together into the w component, while the
	// translations are compressed separately into the xyz components
	if (!previous)
	{
		targetMatrix[0] = (targetMatrix[0] * vs_skinningCompressionScale.wwwx) + vs_skinningCompressionOffset.wwwx;
		targetMatrix[1] = (targetMatrix[1] * vs_skinningCompressionScale.wwwy) + vs_skinningCompressionOffset.wwwy;
		targetMatrix[2] = (targetMatrix[2] * vs_skinningCompressionScale.wwwz) + vs_skinningCompressionOffset.wwwz;
	}
	else
	{
		targetMatrix[0] = (targetMatrix[0] * vs_previousSkinningCompressionScale.wwwx) + vs_previousSkinningCompressionOffset.wwwx;
		targetMatrix[1] = (targetMatrix[1] * vs_previousSkinningCompressionScale.wwwy) + vs_previousSkinningCompressionOffset.wwwy;
		targetMatrix[2] = (targetMatrix[2] * vs_previousSkinningCompressionScale.wwwz) + vs_previousSkinningCompressionOffset.wwwz;
	}

#endif
}

// Fetches the compressed 16-bit matrix from the vertex stream
void FetchSkinningMatrix(sampler skinningMatrixStream, float skinningMatrixIndex, out float4 skinningMatrix[3])
{
#if defined(USE_VERTEX_STREAM_SKINNING)

	float4 matrix_r0;
	float4 matrix_r1;
	float4 matrix_r2;

	// The swizzle on read avoids the need for the CPU to swap for GPU access
	asm {
		vfetch_full matrix_r0.yxwz, skinningMatrixIndex, skinningMatrixStream, DataFormat=FMT_16_16_16_16, Stride=6, PrefetchCount=6
		vfetch_mini matrix_r1.yxwz, DataFormat=FMT_16_16_16_16, Offset=2
		vfetch_mini matrix_r2.yxwz, DataFormat=FMT_16_16_16_16, Offset=4
	};

	skinningMatrix[0] = matrix_r0;
	skinningMatrix[1] = matrix_r1;
	skinningMatrix[2] = matrix_r2;

#endif
}

// Accumulates the contribution of a skinning matrix
void GetSkinningMatrix(inout float4 skinningMatrix[3], float skinningMatrixIndex, float matrixWeight, uniform bool previous = false)
{
#if !defined(EXCLUDE_MODEL_MATRICES) && defined(USE_VERTEX_STREAM_SKINNING)

	float4 curMatrix[3];

	if (!previous)
	{
		FetchSkinningMatrix(vs_skinningMatrixStream, skinningMatrixIndex, curMatrix);
	}
	else
	{
		FetchSkinningMatrix(vs_previousSkinningMatrixStream, skinningMatrixIndex, curMatrix);
	}

	AddMatrix(skinningMatrix, curMatrix, matrixWeight);

#elif !defined(EXCLUDE_MODEL_MATRICES)

	AddMatrix(skinningMatrix, vs_model_skinning_matrices[skinningMatrixIndex], matrixWeight);

#endif
}

void BlendSkinningMatrices(out float4 skinningMatrix[3], float4 nodeIndices, float4 nodeWeights, uniform int maxCount, uniform bool previousFrame = false)
{
	// Zero the matrix to begin with so we can accumulate directly into it
	skinningMatrix[0] = skinningMatrix[1] = skinningMatrix[2] = float4(0,0,0,0);

	// The first matrix will always be used, so process it outside the loop
	GetSkinningMatrix(skinningMatrix, nodeIndices[0], nodeWeights[0], previousFrame);

#if !defined(cgfx)
	[unroll]
#endif
	for (int i = 1; i < maxCount; ++i)
	{
#if defined(USE_VERTEX_STREAM_SKINNING)
		// Weights are sorted, so kill the loop if/when we hit zero contribution
		[branch]
		if (nodeWeights[i] == 0.0)
		{
			break;
		}
#endif

		// Accumulate this matrix
		GetSkinningMatrix(skinningMatrix, nodeIndices[i], nodeWeights[i], previousFrame);
	}

#if !defined(EXCLUDE_MODEL_MATRICES) && defined(USE_VERTEX_STREAM_SKINNING)
	// Convert from compressed skinning matrix space to world space
	DecompressSkinningMatrix(skinningMatrix, previousFrame);
#endif
}


void deform_flat_world(
	inout s_world_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
}

void deform_world(
	inout s_world_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_world(vertex, vertexColor, local_to_world_transform);
}

void deform_previous_world(
	inout s_world_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_world(vertex, vertexColor, local_to_world_transform);

	CopyMatrix(local_to_world_transform, vs_previous_model_world_matrix);
}

void deform_flat_rigid(
	inout s_rigid_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
}

void deform_rigid(
	inout s_rigid_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_rigid(vertex, vertexColor, local_to_world_transform);
}

void deform_previous_rigid(
	inout s_rigid_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_rigid(vertex, vertexColor, local_to_world_transform);

	// Use the previous matrix
	CopyMatrix(local_to_world_transform, vs_previous_model_world_matrix);
}



#if !defined(EXCLUDE_MODEL_MATRICES)
void deform_flat_skinned(
	inout s_skinned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	float4 position;
	float sum_of_weights= dot(vertex.node_weights.xyzw, 1.0f);

	// normalize the node weights so that they sum to 1
	vertex.node_weights= vertex.node_weights/sum_of_weights;

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
	BlendSkinningMatrices(local_to_world_transform, vertex.node_indices, vertex.node_weights, 4);
}

void deform_skinned(
	inout s_skinned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_skinned(vertex, vertexColor, local_to_world_transform);
}

void deform_previous_skinned(
	inout s_skinned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	float4 position;
	float sum_of_weights= dot(vertex.node_weights.xyzw, 1.0f);

	// normalize the node weights so that they sum to 1
	vertex.node_weights= vertex.node_weights/sum_of_weights;

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
	BlendSkinningMatrices(local_to_world_transform, vertex.node_indices, vertex.node_weights, 4, true);
}
#endif // !defined(EXCLUDE_MODEL_MATRICES)





#if !defined(EXCLUDE_MODEL_MATRICES)
void deform_flat_rigid_boned(
	inout s_rigid_boned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	float4 position;

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
	BlendSkinningMatrices(local_to_world_transform, vertex.node_indices.xxxx, 1, 1);
}

void deform_rigid_boned(
	inout s_rigid_boned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	deform_flat_rigid_boned(vertex, vertexColor, local_to_world_transform);
}

void deform_previous_rigid_boned(
	inout s_rigid_boned_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	float4 position;

	DecompressPosition(vertex.position);
	DecompressTexcoord(vertex.texcoord);
	DecompressTexcoord(vertex.texcoord1);
	BlendSkinningMatrices(local_to_world_transform, vertex.node_indices.xxxx, 1, 1, true);
}
#endif // !defined(EXCLUDE_MODEL_MATRICES)






void deform_rigid_blendshaped(
	inout s_rigid_blendshaped_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
#if DX_VERSION == 11
	vertex.position.xyz += vertex.blendshape_position.xyz;
	vertex.position.w = vertex.blendshape_position.w;
	vertex.normal.xyz += vertex.blendshape_normal.xyz;
	vertex.normal.w = vertex.blendshape_normal.w;
#endif

	vertexColor = 1.0f;
	vertexColor.r = 1.0f - vertex.position.w;
	vertexColor.b = 1.0f - vertex.normal.w;

#if !defined(cgfx)
	deform_rigid((s_rigid_vertex)vertex, vertexColor, local_to_world_transform);
#endif

	// Make the tangent orthogonal to the normal
	vertex.tangent.xyz -= vertex.normal.xyz * (dot(vertex.normal.xyz, vertex.tangent.xyz) / dot(vertex.normal.xyz, vertex.normal.xyz));
}

// unimplemented...
#define deform_previous_rigid_blendshaped deform_rigid_blendshaped


#if !defined(EXCLUDE_MODEL_MATRICES)
void deform_skinned_blendshaped(
	inout s_skinned_blendshaped_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
#if DX_VERSION == 11
	vertex.position.xyz += vertex.blendshape_position.xyz;
	vertex.position.w = vertex.blendshape_position.w;
	vertex.normal.xyz += vertex.blendshape_normal.xyz;
	vertex.normal.w = vertex.blendshape_normal.w;
#endif

	vertexColor = 1.0f;
	vertexColor.r = 1.0f - vertex.position.w;
	vertexColor.b = 1.0f - vertex.normal.w;

#if !defined(cgfx)
	deform_skinned((s_skinned_vertex)vertex, vertexColor, local_to_world_transform);
#endif

	// Make the tangent orthogonal to the normal
	vertex.tangent.xyz -= vertex.normal.xyz * (dot(vertex.normal.xyz, vertex.tangent.xyz) / dot(vertex.normal.xyz, vertex.normal.xyz));
}

void deform_previous_skinned_blendshaped(
	inout s_skinned_blendshaped_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
#if DX_VERSION == 11
	vertex.position.xyz += vertex.blendshape_position.xyz;
	vertex.position.w = vertex.blendshape_position.w;
	vertex.normal.xyz += vertex.blendshape_normal.xyz;
	vertex.normal.w = vertex.blendshape_normal.w;
#endif

	vertexColor = 1.0f;
	vertexColor.r = 1.0f - vertex.position.w;
	vertexColor.b = 1.0f - vertex.normal.w;

#if !defined(cgfx)
	deform_previous_skinned((s_skinned_vertex)vertex, vertexColor, local_to_world_transform);
#endif

	// Make the tangent orthogonal to the normal
	vertex.tangent.xyz -= vertex.normal.xyz * (dot(vertex.normal.xyz, vertex.tangent.xyz) / dot(vertex.normal.xyz, vertex.normal.xyz));
}

#endif // !defined(EXCLUDE_MODEL_MATRICES)

void deform_position_only(
	inout s_position_only_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	DecompressPosition(vertex.position);
}


void deform_tiny_position(
	inout s_tiny_position_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);
	DecompressPosition(vertex.position);
}

void deform_tiny_position_projective(
	inout s_tiny_position_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	CopyMatrix(local_to_world_transform, vs_model_world_matrix);

	DecompressPosition(vertex.position);
	vertex.position.yz *= vertex.position.x;		// x is forward vector, scales yz
}

#if !defined(EXCLUDE_MODEL_MATRICES)
void deform_object_imposter(
	inout s_object_imposter_vertex vertex,
	inout float4 vertexColor,
	inout float4 local_to_world_transform[3])
{
	int node_index = 0;
#if defined(xenon) || (DX_VERSION == 11)
	// check for skinned imposters
	if (!vs_render_rigid_imposter)
	{
		node_index =  (vertex.position.w + (1.0f/512.0f)) * 255.f; // decompress node index from last byte
	}
#endif //xenon/pc

	BlendSkinningMatrices(local_to_world_transform, node_index, 1.0, 1);

	DecompressPosition(vertex.position);
}
#endif // !defined(EXCLUDE_MODEL_MATRICES)

#endif 	// !defined(__DEFORM_FXH)
