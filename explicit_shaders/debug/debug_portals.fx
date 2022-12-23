
#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "debug_portals_registers.fxh"


void default_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out float3 position_copy : TEXCOORD0)
{
	out_position = mul(input.position, vs_view_view_projection_matrix);
	position_copy = input.position;
}


float4 default_ps(
	in float4 screen_position : SV_Position,
	in float3 position : TEXCOORD0) : SV_Target
{
//	float3 grid=	(frac(position.rgb) < 0.1f) + (frac(position.rgb * 5.0f) < 0.1f);
//	float alpha=	1.0f - saturate(dot(grid, float3(1.0f, 1.0f, 1.0f)));
//	return float4(color.rgb, color.a * alpha);

//	float3 distance3=		min(abs(frac(position.rgb) - 0.5f), 0.2f * abs(frac(position.rgb * 5.0f) - 0.5f));

	float4 gradients;
#if 1
	gradients.xyzw=		1.0f;
#else // !pc
	float4 gradients2;
	asm {
		getGradients gradients,		position.xy, vector_map
		getGradients gradients2,	position.zy, vector_map
	};
	
	gradients.x=	sqrt(dot(gradients.xy, gradients.xy));
	gradients.y=	sqrt(dot(gradients.zw, gradients.zw));
	gradients.z=	sqrt(dot(gradients2.xy, gradients2.xy));
#endif // !pc

	float	frequency=	5.0f;
	float	frequency2=	0.5f;
	float	width=		0.1f;
	float3 distance2=		2.0f * abs(frac(position.rgb * frequency) - 0.5f) - width;
	float3 distance3=		2.0f * abs(frac(position.rgb * frequency2) - 0.5f) - width;
	distance3=	min(distance3 * 10.0f, distance2);

	float3 scale= 0.08000;		// antialias_tweak;

	scale.x /= gradients.x;
	scale.y /= gradients.y;
	scale.z /= gradients.z;

//	scale= max(scale, 1.0f);		// scales smaller than 1.0 result in '100% transparent' areas appearing as semi-opaque
//	float distance=	distance3.x;	//min(min(distance3.x, distance3.y), distance3.z);
//	float vector_alpha= saturate(distance * min(scale, 1000.000000) + 0.5f);		// vector_sharpness = 1000

	float3 vector_alpha= saturate(distance3 * scale + 0.5f);
	
//	float alpha=	vector_alpha.x * vector_alpha.y * vector_alpha.z;
	float alpha=	dot(vector_alpha, float3(0.33f, 0.33f, 0.33f));

	return float4(color.rgb, color.a * alpha);
}


BEGIN_TECHNIQUE _default
{
	pass world
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

