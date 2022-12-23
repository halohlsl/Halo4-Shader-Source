#if !defined(__VERTEX_TYPES_FXH)
#define __VERTEX_TYPES_FXH

#include "core/core.fxh"


typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float2 texcoord1:		TEXCOORD5;
    float3 normal:			NORMAL;
    float4 tangent:			TANGENT;
}
	s_world_vertex,
	s_flat_world_vertex,
	s_world_tessellated_vertex;


typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float4 normal:			NORMAL;
#if !defined(cgfx)
    float4 tangent:			TANGENT;
    float2 texcoord1:		TEXCOORD5;
#else
    float2 texcoord1:		TEXCOORD1;
    float3 tangent:			TEXCOORD6;
	float3 binormal:		TEXCOORD7;
	float4 vertexColor:		COLOR0;
#endif
}
	s_rigid_vertex,
	s_flat_rigid_vertex,
	s_rigid_tessellated_vertex
#if DX_VERSION == 9	
	, s_blendshape_rigid_vertex,
	s_blendshape_rigid_blendshaped_vertex,
	s_rigid_blendshaped_vertex
#endif
	;
	
#if DX_VERSION == 11
typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float4 normal:			NORMAL;
    float4 tangent:			TANGENT;
    float2 texcoord1:		TEXCOORD5;
	
	float4 blendshape_position: POSITION1;
	float4 blendshape_normal: NORMAL1;
}	s_blendshape_rigid_vertex,
	s_blendshape_rigid_blendshaped_vertex,
	s_rigid_blendshaped_vertex;
#endif

typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float2 texcoord1:		TEXCOORD5;
    float4 normal:			NORMAL;
    float4 tangent:			TANGENT;
#if DX_VERSION == 11
    uint4 node_indices:		BLENDINDICES;
#else
    float4 node_indices:	BLENDINDICES;
#endif
    float4 node_weights:	BLENDWEIGHT;
}
	s_skinned_vertex,
	s_flat_skinned_vertex,
	s_skinned_tessellated_vertex
#if DX_VERSION == 9	
	, s_blendshape_skinned_vertex,
	s_blendshape_skinned_blendshaped_vertex,
	s_skinned_blendshaped_vertex
#endif
	;
	
#if DX_VERSION == 11
typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float2 texcoord1:		TEXCOORD5;
    float4 normal:			NORMAL;
    float4 tangent:			TANGENT;
    uint4 node_indices:		BLENDINDICES;
    float4 node_weights:	BLENDWEIGHT;
	
	float4 blendshape_position: POSITION1;
	float4 blendshape_normal: NORMAL1;
}	s_blendshape_skinned_vertex,
	s_blendshape_skinned_blendshaped_vertex,
	s_skinned_blendshaped_vertex;
#endif

typedef struct
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float2 texcoord1:		TEXCOORD5;
    float3 normal:			NORMAL;
    float4 tangent:			TANGENT;
#if DX_VERSION == 11
    uint1 node_indices:		BLENDINDICES;
#else
    float1 node_indices:	BLENDINDICES;
#endif
}
	s_rigid_boned_vertex;

typedef struct
{
	float4 position:		POSITION0;
}
	s_position_only_vertex,
 	s_tiny_position_vertex,
	s_patchy_fog_vertex,
	s_polyart_vertex;

typedef struct
{
#ifdef pc
	float4 positionAndAlpha:	POSITION0;
#else
	float3 positionAndAlpha:	POSITION0;
#endif
}
	s_vectorartVertex;

typedef struct
{
	float4 positionAndAlpha:	POSITION0;
	float2 texCoord:			TEXCOORD0;
}
	s_polyartUvVertex;


typedef struct
{
	int index:				INDEX;
	float2 address:			TEXCOORD1;
}
	s_particle_vertex,
#if DX_VERSION != 11
	s_particle_model_vertex,
#endif
	TracerVertex,
	LightVolumeVertex;

#if DX_VERSION == 11
typedef struct
{
	float4 position:		POSITION;
	float4 texcoord:		TEXCOORD;
	float3 normal:			NORMAL;
} s_particle_model_vertex;
#endif
	
struct s_screen_vertex
{
    float2 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float4 color:			COLOR0;
};

struct s_bink_vertex
{
    float2 position:		POSITION;
    float4 texcoord:		TEXCOORD0;
};

struct s_debug_vertex
{
	float3 position:		POSITION;
	float4 color:			COLOR0;
};

struct s_transparent_vertex
{
	float3 position:		POSITION;
	float2 texcoord:		TEXCOORD0;
	float4 color:			COLOR0;
};

// lighting model vertex structures
struct s_lightmap_per_pixel
{
    float2 texcoord:		TEXCOORD1;
};

struct s_lightmap_per_vertex
{
    float3 color:			COLOR0;
};

struct s_light_volume_vertex
{
	int index:				INDEX;
};

struct s_chud_vertex_simple
{
	float2 position:		POSITION;
	float2 texcoord:		TEXCOORD0;
};

struct s_chud_vertex_fancy
{
	float3 position:		POSITION;
	float4 color:			COLOR0;
	float2 texcoord:		TEXCOORD0;
};

struct s_implicit_vertex
{
	float4 position:		POSITION;
	float2 texcoord:		TEXCOORD0;
};

struct s_decorator_vertex
{
	// vertex data (stream 0)
	float3 position:		POSITION0;
	float2 texcoord:		TEXCOORD0;

	// instance data (stream 1)
	float4 instance_position:POSITION1;
	float4 instance_orientation:NORMAL1;
	float4 instance_color:	COLOR1;

	// also stream 2 => vertex index (int)
};

//	has been ingored
struct s_water_vertex
{
	float4 position:		POSITION0;
};

//	has been ingored
struct s_ripple_particle_vertex
{
	float2 position:		POSITION0;
};

struct s_shader_cache_vertex
{
    float4 position:		POSITION;
    float2 texcoord:		TEXCOORD0;
    float3 normal:			NORMAL;
    float3 tangent:			TANGENT;
	float4 light_param:		TEXCOORD1;
};

// vertex indices for both non-tessellated or tessellated geometry
#ifndef pc
struct s_vertex_type_trilist_index
{
	int3 index:				INDEX;
	float3 uvw:				BARYCENTRIC;
};
#endif

// refer to: _vertex_type_object_imposter
struct s_object_imposter_vertex
{
	float4 position					:POSITION;
    float3 normal					:NORMAL;
	float3 diffuse					:TEXCOORD1;
	float3 ambient					:TEXCOORD2;
	float4 specular_shininess		:TEXCOORD3;
	float4 change_colors_of_diffuse	:TEXCOORD4;
	float4 change_colors_of_specular:TEXCOORD5;
};

#endif 	// !defined(__VERTEX_TYPES_FXH)