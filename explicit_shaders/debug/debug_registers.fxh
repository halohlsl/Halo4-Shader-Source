#if DX_VERSION == 9

float4 debug_color : register(c16);
float debug_interp : register(c17);	// 0..1 vertexColor..color

// texture transform
float4 debug_mesh_xform : register(c17);

// misc data
//	.x - top mip level of the texture (0=4k, 1=2k, 2=1k, 3=512, ... )
//  .y -
//  .z -
//  .w -
float4 debug_mesh_misc : register(c18);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DebugPS)
	CBUFFER_CONST(DebugPS,		float4,		debug_color,		k_ps_debug_color)
	CBUFFER_CONST(DebugPS,		float,		debug_interp,		k_ps_debug_interp)
	CBUFFER_CONST(DebugPS,		float3,		debug_padding,		k_ps_debug_padding)
CBUFFER_END

CBUFFER_BEGIN(DebugMeshPS)
	CBUFFER_CONST(DebugMeshPS,	float4,		debug_mesh_xform,	k_ps_debug_mesh_xform)
	CBUFFER_CONST(DebugMeshPS,	float4,		debug_mesh_misc,	k_ps_debug_mesh_misc)
CBUFFER_END

#endif
