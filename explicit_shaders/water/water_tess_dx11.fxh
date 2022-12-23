//
// File:	 water_tess_dx11.fxh
// Author:	 DeanoC
// Date:	 26/03/14
//
// Notes:
//

#include "core/core.fxh"
#include "../explicit_shaders/water/water_types_dx11.fxh"
#include "../explicit_shaders/water/water_registers_dx11.fxh"

static const float MAX_TESS_LEVEL = 4.0f;
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

void splitTri( 	float3 v0,
				float3 v1,
				float3 v2,
				out float3 nv[3] ) {
	nv[0] = (v0 + v1) / 2;
	nv[1] = (v1 + v2) / 2;
	nv[2] = (v2 + v0) / 2;
}

s_water_render_vertex_out interpolateVertex( 
						const s_water_in_triangle tri,
						const float3 baryV ) {
	s_water_render_vertex_out v;
	v.position = (tri.pos[0] * baryV.x) + (tri.pos[1] * baryV.y) + (tri.pos[2] * baryV.z);
	v.texcoord = (tri.tex[0] * baryV.x) + (tri.tex[1] * baryV.y) + (tri.tex[2] * baryV.z);
	v.normal = (tri.nml[0] * baryV.x) + (tri.nml[1] * baryV.y) + (tri.nml[2] * baryV.z);
	v.tangent = (tri.tan[0] * baryV.x) + (tri.tan[1] * baryV.y) + (tri.tan[2] * baryV.z);
	v.btexcoord = (tri.btex[0] * baryV.x) + (tri.btex[1] * baryV.y) + (tri.btex[2] * baryV.z);
	v.lmtex = (tri.lmtex[0] * baryV.x) + (tri.lmtex[1] * baryV.y) + (tri.lmtex[2] * baryV.z);
	v.wscl = (tri.wscl[0] * baryV.x) + (tri.wscl[1] * baryV.y) + (tri.wscl[2] * baryV.z);

	return v;
}

void outputTri( const s_water_in_triangle tri,
				const int outTriIndex,
				const float3 baryV0,
				const float3 baryV1,
				const float3 baryV2 ) {

	outputVertices[ outTriIndex+0 ] = interpolateVertex(tri, baryV0);
	outputVertices[ outTriIndex+1 ] = interpolateVertex(tri, baryV1);
	outputVertices[ outTriIndex+2 ] = interpolateVertex(tri, baryV2);
}

void Do4Tri(	const s_water_in_triangle tri,
				const uint writeIndex,
				const float3 b0,
				const float3 b1,
				const float3 b2 ) {

	float3 nb[3];

	splitTri( b0, b1, b2, nb );
	outputTri(tri, writeIndex+(0*3),  b0, nb[0],  nb[2] );
	outputTri(tri, writeIndex+(1*3),  b1, nb[1],  nb[0] );
	outputTri(tri, writeIndex+(2*3),  b2, nb[2],  nb[1] );
	outputTri(tri, writeIndex+(3*3), nb[0], nb[1], nb[2] );
}

void Do16Tri(	const s_water_in_triangle tri,
				const uint writeIndex,
				const float3 b0,
				const float3 b1,
				const float3 b2 ) {
	float3 nb[3];

	splitTri( b0, b1, b2, nb );
	Do4Tri( tri, writeIndex + (0*3), b0, nb[0],  nb[2] );
	Do4Tri( tri, writeIndex + (4*3), b1, nb[1],  nb[0] );
	Do4Tri( tri, writeIndex + (8*3), b2, nb[2],  nb[1] );
	Do4Tri( tri, writeIndex + (12*3), nb[2], nb[0], nb[1] );
}

void Do64Tri(	const s_water_in_triangle tri,
				const uint writeIndex,
				const float3 b0,
				const float3 b1,
				const float3 b2 ) {
	float3 nb[3];

	splitTri( b0, b1, b2, nb );
	Do16Tri( tri, writeIndex + (0*3), b0, nb[0],  nb[2] );
	Do16Tri( tri, writeIndex + (16*3), b1, nb[1],  nb[0] );
	Do16Tri( tri, writeIndex + (32*3), b2, nb[2],  nb[1] );
	Do16Tri( tri, writeIndex + (48*3), nb[2], nb[0], nb[1] );
}
void Do256Tri(	const s_water_in_triangle tri,
				const uint writeIndex,
				const float3 b0,
				const float3 b1,
				const float3 b2 ) {
	float3 nb[3];

	splitTri( b0, b1, b2, nb );
	Do64Tri( tri, writeIndex + (0*3), b0, nb[0],  nb[2] );
	Do64Tri( tri, writeIndex + (64*3), b1, nb[1],  nb[0] );
	Do64Tri( tri, writeIndex + (128*3), b2, nb[2],  nb[1] );
	Do64Tri( tri, writeIndex + (192*3), nb[2], nb[0], nb[1] );
}

void tesselate(	const s_water_in_triangle tri,
				int3 edgeFactor ) {
	const float3 b0 = { 1, 0, 0 };
	const float3 b1 = { 0, 1, 0 };
	const float3 b2 = { 0, 0, 1 };

	uint writeIndex;

	// check easy case of all same tesselation level
	if( edgeFactor.x == edgeFactor.y &&
		edgeFactor.x == edgeFactor.z ) {

		// special case no tesselation
		if( edgeFactor.x == 0 ) {
			InterlockedAdd(outputIndirect[0], 3, writeIndex );
			
			for( int i = 0; i < 3; ++i ) {
				s_water_render_vertex_out v;

				v.position = tri.pos[i];
				v.texcoord = tri.tex[i];
				v.normal = tri.nml[i];
				v.tangent = tri.tan[i];
				v.btexcoord = tri.btex[i];
				v.lmtex = tri.lmtex[i];
				v.wscl = tri.wscl[i];			
				outputVertices[ writeIndex+i ] = v;
			}

		} else if( edgeFactor.x == 1) {
			// do the atomic increment manually outside DoXTri to reduce 
			// atomic memory traffic
			InterlockedAdd(outputIndirect[0], 4*3, writeIndex );
			Do4Tri( tri, writeIndex, b0, b1, b2 );
		} else if( edgeFactor.x == 2){
			InterlockedAdd(outputIndirect[0], 16*3, writeIndex );
			Do16Tri( tri, writeIndex, b0, b1, b2 );
		} else /*if( edgeFactor.x == 3)*/{
			InterlockedAdd(outputIndirect[0], 64*3, writeIndex );
			Do64Tri( tri, writeIndex, b0, b1, b2 );
		} /*else if( edgeFactor.x == 4){
			InterlockedAdd(outputIndirect[0], 256*3, writeIndex );
			Do256Tri( tri, writeIndex, b0, b1, b2 );
		} else {
			// should never happen if MAX_TESS_LEVEL is set correctly
			InterlockedAdd(outputIndirect[0], 256*3, writeIndex );
			Do256Tri( tri, writeIndex, b0, b1, b2 );
		}*/
	}	
}

[numthreads(64,1,1)]
void WaterTessellationCS( uint dispatchThreadId : SV_DispatchThreadID )
{
	if( dispatchThreadId == 0 ) {
		// no need to synchronise this - only a single thread will write to this location
		outputIndirect[1] = 1;
	}

	int index = dispatchThreadId + water_index_offset.x;

	// handle end of vertex array
	if( dispatchThreadId >= num_input_triangles ) {
		return;
	}

	s_water_in_triangle tri = inputTriangles[ index.x ];

	bool vis = FaceVisibilityTest( k_vs_tess_camera_position.xyz,
						k_vs_tess_camera_forward.xyz,
						k_vs_tess_camera_diagonal.xyz,
						tri.pos[0],
						tri.pos[1],
						tri.pos[2] );

	if( vis == true ){
		int3 edgeFactor;
		edgeFactor.x = floor(EdgeTessellationLevel( k_vs_tess_camera_position.xyz,
									  tri.pos[0],
									  tri.pos[1], 
									  k_vs_tess_camera_diagonal.x ) );
		edgeFactor.y = floor( EdgeTessellationLevel( k_vs_tess_camera_position.xyz,
									  tri.pos[1],
									  tri.pos[2], 
									  k_vs_tess_camera_diagonal.x ) );
		edgeFactor.z = floor( EdgeTessellationLevel( k_vs_tess_camera_position.xyz,
									  tri.pos[2],
									  tri.pos[0], 
									  k_vs_tess_camera_diagonal.x ) );

		// tmp
		edgeFactor.y = edgeFactor.z = edgeFactor.x;
		tesselate( tri, edgeFactor );	
	}
}

#if !defined(cgfx)

BEGIN_TECHNIQUE
{
	pass water
	{
		SET_COMPUTE_SHADER( WaterTessellationCS() );
	}
}

#endif
