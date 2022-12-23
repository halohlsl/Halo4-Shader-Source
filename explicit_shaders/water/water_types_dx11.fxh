#if !defined( WATER_TYPES_DX11_FXH)
#define WATER_TYPES_DX11_FXH

// TODO pack this structure
typedef struct {
	float3 pos[3];
	float2 tex[3];
	float3 nml[3];
	float3 tan[3];
	float2 btex[3];
	float2 lmtex[3];
	float1 wscl[3];

} s_water_in_triangle;

typedef struct 
{
	float3 position;
    float2 texcoord;
    float3 normal;
    float3 tangent;
    float2 btexcoord;
    float2 lmtex;
    float1 wscl;
} s_water_render_vertex_out;

typedef struct
{
	uint vertexCountPerInstance;
	uint instanceCount;
	uint startVertexLocation;
	uint startInstanceLocation;

} s_water_render_instance_indirect;
#endif // endif 