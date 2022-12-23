//
// File:	 water_tesselation.fxh
// Author:	 aluedke
// Date:	 04/16/12
//
// Water shader header that calculates the appropriate tessellation level
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#include "core/core.fxh"
#include "water_tessellation_registers.fxh"



#if defined(xenon)
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(wave_tessellation_level, "Wave Tessellation Level", "", 0, 4, 1.0f);
#include "used_vertex_float.fxh"


static const float MAX_TESS_LEVEL = 15.0f;
static const float ANGLE_TO_TESS_LEVEL_RATIO = 40.0f;
static const float TESS_LEVEL_DISTANCE_DAMP = 40;

float EdgeTessellationLevel(
	  float3 camera_position,
	  float3 pos0,
	  float3 pos1,
	  float camera_sin)
{
	float3 center = (pos0 + pos1) * 0.5f;
	float radius = length(pos0 - center);
	float distance = length(center - camera_position);
	distance = max(distance, 0.001f); // avoid to be zero

	if (radius > distance)
	{
		return MAX_TESS_LEVEL;	// boudning sphere contains eyes, so big ...
	}
	else
	{
		float sin_theta = radius / distance;

		float distance_coefficient = saturate(1.0f - distance / TESS_LEVEL_DISTANCE_DAMP);
		distance_coefficient = distance_coefficient * distance_coefficient;
		float angle_to_tess = ANGLE_TO_TESS_LEVEL_RATIO * distance_coefficient * wave_tessellation_level;

		return min(sin_theta * angle_to_tess / camera_sin, MAX_TESS_LEVEL);
	}
}

bool FaceVisibilityTest(
	in const float3 cameraPosition,
	in const float3 cameraForward,
	in const float3 cameraDiagonal,
	in const float3 pos0,
	in const float3 pos1,
	in const float3 pos2)
{
	float3 faceCenter = (pos0 + pos1 + pos2) / 3.0;
	float faceRadius = length(pos0 - faceCenter);
	faceRadius = max(faceRadius, length(pos1 - faceCenter));
	faceRadius = max(faceRadius, length(pos2 - faceCenter));

	float3 faceDir = faceCenter - cameraPosition;
	float faceDistance = length(faceDir);

	// sphere contains eye, KEEP
	if (faceRadius > faceDistance)
	{
		return true;
	}

	// compute face bounding sphere angle to eye position
	float sphereSinAngle = faceRadius / faceDistance;
	float sphereCosAngle = sqrt(1 - sphereSinAngle * sphereSinAngle);

	// compute face center angle to eye position
	faceDir = normalize(faceDir);
	float centerCosAngle = dot(faceDir, cameraForward);
	float centerSinAngle = sqrt(1 - centerCosAngle * centerCosAngle);

	// compute angle to sphere boundary
	float boundSinAngle = centerSinAngle * sphereCosAngle - centerCosAngle * sphereSinAngle;
	float boundCosAngle = centerCosAngle * sphereCosAngle + centerSinAngle * sphereSinAngle;

	// sphere cross the forward line of eye, KEEP
	if (boundSinAngle < 0)
	{
		return true;
	}

	// sphere is on the other side of eye, CULL
	if (boundCosAngle < 0)
	{
		return false;
	}

	//	bund angle larger than view frustrum diagonal sin, CULL
	return (boundSinAngle > cameraDiagonal.x) ? false : true;
}


// Memexport the tesselation level for a given triangle
void WaterTessellationVS(
	in uint waterVertexIndex : SV_VertexID)
{
	static float4 x_const01= { 0, 1, 0, 0 };
	float level0, level1, level2;

	// indices of vertices
	int index = waterVertexIndex + vs_water_index_offset.x;

#if 0		// TODO (aluedke): Kick tessellation to maximum during screenshots
	if (k_is_under_screenshot)
	{
		level0 = level1 = level2 = MAX_TESS_LEVEL;
	}
    else
#endif
	{
		// Fetch vertex indices for triangle
		float4 vertexIndex0, vertexIndex1, vertexIndex2;
		asm {
			vfetch vertexIndex0, index, color0
			vfetch vertexIndex1, index, color1
			vfetch vertexIndex2, index, color2
		};

		// Fetch positions of vertices in world space
		float4 vertexPosition0, vertexPosition1, vertexPosition2;
		asm {
			vfetch vertexPosition0, vertexIndex0.x, position0
			vfetch vertexPosition1, vertexIndex1.x, position0
			vfetch vertexPosition2, vertexIndex2.x, position0
		};

		// Calculate the tesellation levels base don the edges
		level0 = EdgeTessellationLevel(k_vs_tess_camera_position, vertexPosition0.xyz, vertexPosition1.xyz, k_vs_tess_camera_diagonal.x);
		level1 = EdgeTessellationLevel(k_vs_tess_camera_position, vertexPosition1.xyz, vertexPosition2.xyz, k_vs_tess_camera_diagonal.x);
		level2 = EdgeTessellationLevel(k_vs_tess_camera_position, vertexPosition2.xyz, vertexPosition0.xyz, k_vs_tess_camera_diagonal.x);

		float isFaceVisible = FaceVisibilityTest(k_vs_tess_camera_position.xyz,
												 k_vs_tess_camera_forward.xyz,
												 k_vs_tess_camera_diagonal.xyz,
												 vertexPosition0.xyz,
												 vertexPosition1.xyz,
												 vertexPosition2.xyz);

		level0 *= isFaceVisible;
		level1 *= isFaceVisible;
		level2 *= isFaceVisible;
	}

	int out_index_0 = index * 3;
	int out_index_1 = index * 3 + 1;
	int out_index_2 = index * 3 + 2;

	// export
	asm {
		alloc export = 1
		mad eA, out_index_0, x_const01, vs_water_memexport_address
		mov eM0, level0

		alloc export = 1
		mad eA, out_index_1, x_const01, vs_water_memexport_address
		mov eM0, level1

		alloc export = 1
		mad eA, out_index_2, x_const01, vs_water_memexport_address
		mov eM0, level2
    };
}




struct s_vertex_type_water_shading
{
	int index		:	INDEX;

	// tessellation parameter
	float3 uvw		:	BARYCENTRIC;
	int quad_id		:	QUADID;
};


struct s_water_render_vertex
{
	float4 position;
	float4 texcoord;
	float4 normal;
	float4 tangent;
	float4 binormal;
	float4 base_tex;
	float4 lm_tex;
};

// The following defines the protocol for passing interpolated data between the vertex shader
// and the pixel shader.
struct s_water_interpolators
{
	float4 position		:SV_Position0;
	float4 texcoord		:TEXCOORD0;
	float4 normal		:TEXCOORD1;
	float4 tangent		:TEXCOORD2;
	float4 binormal		:TEXCOORD3;
	float4 position_ss	:TEXCOORD4;		//	position in screen space
	float4 incident_ws	:TEXCOORD5;		//	view incident direction in world space, incident_ws.w store the distannce between eye and current vertex
	float4 position_ws  :TEXCOORD6;
	float4 base_tex		:TEXCOORD7;
	float4 lm_tex		:TEXCOORD8;
};



static float4 barycentric_interpolate(
			float4 a,
			float4 b,
			float4 c,
			float3 weights)
{
	return a*weights.z + b*weights.y + c*weights.x;
}


// interpolate vertex porperties accroding tesselation information
s_water_render_vertex GetWaterVertex(
	uniform s_vertex_type_water_shading IN,
	uniform bool doTessellation)
{
	s_water_render_vertex OUT;

	if (doTessellation)
	{
		// indices of vertices
		int index= IN.index + vs_water_index_offset.x;
		float4 v_index0, v_index1, v_index2;
		asm {
			vfetch v_index0, index, color0
			vfetch v_index1, index, color1
			vfetch v_index2, index, color2
		};

		//	fetch vertex porpertices
		float4 pos0, pos1, pos2;
		float4 tex0, tex1, tex2;
		float4 nml0, nml1, nml2;
		float4 tan0, tan1, tan2;
		float4 btex0, btex1, btex2;
		float4 lm_tex0, lm_tex1, lm_tex2;


		int v0_index_mesh= v_index0.x;
		int v0_index_water= v_index0.y;

		int v1_index_mesh= v_index1.x;
		int v1_index_water= v_index1.y;

		int v2_index_mesh= v_index2.x;
		int v2_index_water= v_index2.y;

		asm {
			vfetch pos0, v0_index_mesh, position0
			vfetch tex0, v0_index_mesh, texcoord0
			vfetch nml0, v0_index_mesh, normal0
			vfetch tan0, v0_index_mesh, tangent0
			vfetch lm_tex0, v0_index_mesh, texcoord1
			vfetch btex0, v0_index_water, position1

			vfetch pos1, v1_index_mesh, position0
			vfetch tex1, v1_index_mesh, texcoord0
			vfetch nml1, v1_index_mesh, normal0
			vfetch tan1, v1_index_mesh, tangent0
			vfetch lm_tex1, v1_index_mesh, texcoord1
			vfetch btex1, v1_index_water, position1

			vfetch pos2, v2_index_mesh, position0
			vfetch tex2, v2_index_mesh, texcoord0
			vfetch nml2, v2_index_mesh, normal0
			vfetch tan2, v2_index_mesh, tangent0
			vfetch lm_tex2, v2_index_mesh, texcoord1
			vfetch btex2, v2_index_water, position1
		};

		// re-order the weights based on the QuadID
		float3 weights= IN.uvw * (0==IN.quad_id);
		weights+= IN.uvw.zxy * (1==IN.quad_id);
		weights+= IN.uvw.yzx * (2==IN.quad_id);
		weights+= IN.uvw.xzy * (4==IN.quad_id);
		weights+= IN.uvw.yxz * (5==IN.quad_id);
		weights+= IN.uvw.zyx * (6==IN.quad_id);

		// interpoate otuput
		OUT.position= barycentric_interpolate(pos0, pos1, pos2, weights);
		OUT.texcoord= barycentric_interpolate(tex0, tex1, tex2, weights);

		OUT.normal= barycentric_interpolate(nml0, nml1, nml2, weights);
		OUT.tangent= barycentric_interpolate(tan0, tan1, tan2, weights);

		OUT.base_tex= barycentric_interpolate(btex0, btex1, btex2, weights);
		OUT.lm_tex= barycentric_interpolate(lm_tex0, lm_tex1, lm_tex2, weights);


		OUT.normal.xyz = normalize(OUT.normal.xyz);
		OUT.normal.w = 1.0f - OUT.position.w;
		OUT.tangent= normalize(OUT.tangent);
		OUT.binormal= float4(cross(OUT.normal.xyz, OUT.tangent.xyz), 0);
	}
	else
	{
		// indices of vertices
		float in_index= IN.uvw.x; // ###xwan after declaration of uvw and quad_id, Xenon has mistakely put index into uvw.x. :-(
		int t_index;
		[isolate]
		{
			t_index= floor((in_index+0.3f)/3);	//	triangle index
		}

		int v_guid;
		[isolate]
		{
			float temp= in_index - t_index*3 + 0.1f;
			v_guid= (int) temp;
		}

		float4 v_index0, v_index1, v_index2;
		asm {
			vfetch v_index0, t_index, color0
			vfetch v_index1, t_index, color1
			vfetch v_index2, t_index, color2
		};

		float4 v_index= v_index0 * (0==v_guid);
		v_index += v_index1 * (1==v_guid);
		v_index += v_index2 * (2==v_guid);


		//	fetch vertex properties
		float4 pos, tex, nml, tan, bnl, btex, loc, lm_tex;
		int v_index_mesh= v_index.x;
		int v_index_water= v_index.y;

		asm {
			vfetch pos, v_index_mesh, position0
			vfetch tex, v_index_mesh, texcoord0
			vfetch nml, v_index_mesh, normal0
			vfetch tan, v_index_mesh, tangent0
			vfetch lm_tex, v_index_mesh, texcoord1
			vfetch btex, v_index_water, position1
		};

		// interpoate otuput
		OUT.position   = pos;
		OUT.texcoord   = tex;
		OUT.normal     = nml;
		OUT.normal.w   = 1.0f - OUT.position.w;
		OUT.tangent    = tan;
		OUT.binormal   = float4(cross(OUT.normal, OUT.tangent), 0);
		OUT.base_tex   = btex;
		OUT.lm_tex     = lm_tex;
	}

	return OUT;
}


// get vertex properties
s_water_render_vertex get_vertex(
	in const s_vertex_type_water_shading IN)
{
	s_water_render_vertex OUT;

}

#else

// stub a shader for PC
float4 WaterTessellationVS() : SV_Position
{
	return 0;
}

#endif


#if !defined(cgfx)

BEGIN_TECHNIQUE
{
	pass water
	{
		SET_VERTEX_SHADER(WaterTessellationVS());
	}
}

#endif
