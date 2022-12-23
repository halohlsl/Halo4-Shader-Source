#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "engine/engine_parameters.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "shadow_registers.fxh"

#ifndef SAMPLE_PERCENTAGE_CLOSER
#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_PCF_3x3_block
#endif // SAMPLE_PERCENTAGE_CLOSER

#define CAMERA_TO_SHADOW_PROJECTIVE_X ps_shadow_parameters[0]
#define CAMERA_TO_SHADOW_PROJECTIVE_Y ps_shadow_parameters[1]
#define CAMERA_TO_SHADOW_PROJECTIVE_Z ps_shadow_parameters[2]

#define INSCATTER_SCALE		ps_shadow_parameters[3]
#define INSCATTER_OFFSET	ps_shadow_parameters[4]

#define screen_xform ps_shadow_parameters[7]

#define ZBUFFER_SCALE (ps_shadow_parameters[8].r)
#define ZBUFFER_BIAS (ps_shadow_parameters[8].g)
#define SHADOW_PIXELSIZE (ps_shadow_parameters[8].b)
#define DIRECT_KNOCKOUT_FACTOR	ps_shadow_parameters[8].a

#define FADE_RESCALE		ps_shadow_parameters[6].x
#define FADE_REOFFSET		ps_shadow_parameters[6].y

#define SHADOW_DIRECTION_NORMALSPACE (ps_shadow_direction.xyz)





#if !defined(xenon)
const float2 pixel_size = float2(1.0/512.0f, 1.0/512.0f);		// shadow pixel size ###ctchou $TODO THIS NEEDS TO BE PASSED IN!!!  good thing we don't care about PC...
#endif


// default for hard shadow
void default_vs(
	in s_tiny_position_vertex input,
	out float4 screen_position : SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_tiny_position, input, output, local_to_world_transform, screen_position);
}

float sample_percentage_closer_PCF_3x3_block(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)					// 9 samples, 0 predicated
{
#ifndef pc
	[isolate]		// optimization - reduces GPRs
#endif // !pc

	float2 texel= fragment_shadow_position.xy;

	float4 blend= 1.0f;
	float scale= 1.0f / 9.0f;

#ifdef BILINEAR_SHADOWS
#ifndef VERTEX_SHADER
	asm {
		getWeights2D blend.xy, fragment_shadow_position.xy, shadow, MagFilter=linear, MinFilter=linear, OffsetX=0.5, OffsetY=0.5
	};
	blend.zw= 1.0f - blend.xy;
	scale = 1.0f / 4.0f;
#endif // VERTEX_SHADER
#endif // BILINEAR_SHADOWS

	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	float color=	blend.z * blend.w * step(max_depth.z, Sample2DOffsetPoint(shadow, texel, -1.0f, -1.0f).r) +
					1.0f    * blend.w * step(max_depth.y, Sample2DOffsetPoint(shadow, texel, +0.0f, -1.0f).r) +
					blend.x * blend.w * step(max_depth.z, Sample2DOffsetPoint(shadow, texel, +1.0f, -1.0f).r) +
					blend.z * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(shadow, texel, -1.0f, +0.0f).r) +
					1.0f    * 1.0f    * step(max_depth.x, Sample2DOffsetPoint(shadow, texel, +0.0f, +0.0f).r) +
					blend.x * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(shadow, texel, +1.0f, +0.0f).r) +
					blend.z * blend.y * step(max_depth.z, Sample2DOffsetPoint(shadow, texel, -1.0f, +1.0f).r) +
					1.0f    * blend.y * step(max_depth.y, Sample2DOffsetPoint(shadow, texel, +0.0f, +1.0f).r) +
					blend.x * blend.y * step(max_depth.z, Sample2DOffsetPoint(shadow, texel, +1.0f, +1.0f).r);

	return color * scale;
}


#if defined(xenon)
	#ifdef FLOATING_SHADOW
		[reduceTempRegUsage(9)]
	#else
		[reduceTempRegUsage(10)]	
	#endif
#endif
float4 default_ps(in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target
{
#if !defined(xenon)
#if DX_VERSION == 9	
	float2 texture_pos= pixel_pos.xy;
	float pixel_depth= sample2D(zbuffer, texture_pos).r;
	float4 normalSample = sample2DLOD(normal_buffer, texture_pos.xy, 0, 0);
#elif DX_VERSION == 11
	int3 texture_pos = int3(pixel_pos.xy, 0);
	float pixel_depth = zbuffer.t.Load(texture_pos).x;
	float2 normalSample = normal_buffer.t.Load(texture_pos).xy;
#endif
#else
    float pixel_depth;
	float2 normalSample;
    asm
    {
       tfetch2D pixel_depth.x___, pixel_pos, zbuffer, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD=false
       tfetch2D normalSample.xy__, pixel_pos, normal_buffer, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD=false
    };
#endif

//*	
	float4x4 combinedProj;
	combinedProj[0] = ps_shadow_parameters[0];
	combinedProj[1] = ps_shadow_parameters[1];
	combinedProj[2] = ps_shadow_parameters[2];
	combinedProj[3] = ps_shadow_parameters[5];
	
	float4 projectedShadow =  mul(float4(pixel_pos.xy, pixel_depth, 1.0), combinedProj);
	float3 fragment_shadow_projected = projectedShadow.xyz / projectedShadow.w;

#ifdef FLOATING_SHADOW
#else
	#ifdef BLOB
		float shadow_falloff= saturate(abs(pow(fragment_shadow_projected.z*FADE_RESCALE + FADE_REOFFSET, 3.0))/0.8);	// falloff on both sides, / 0.8 and saturated to make extra sure it falls off before reaching the edges
	#else
		float shadow_falloff= max(fragment_shadow_projected.z*FADE_RESCALE + FADE_REOFFSET, 0.0);	// shift z-depth falloff to bottom three-quarters of the shadow volume (no depth falloff in top quarter)
		shadow_falloff = shadow_falloff * shadow_falloff / 2.25;
	#endif // BLOB
	
	float shadow_darkness = ps_constant_shadow_alpha.r * (1-shadow_falloff);	
	
#ifdef xenon
	float3 normal = DecodeNormalSigned(normalSample.xy);
#else
	float3 normal = DecodeNormal(normalSample.xy);
#endif
	
	float cosine = dot(normal, SHADOW_DIRECTION_NORMALSPACE.xyz);
	
	#ifndef NO_NORMAL_TEST	
		// we mask out the incident radiance in the static pass
		// so we don't need to calculate lighting here.
		// what we need is to kill the light that is facing away from the direction.
		float cosine_falloff= saturate(0.65f + cosine*5);		// push the shadow line slightly past 180 degrees, otherwise we get a bright edge of analytical around the horizon.   this also gives us slightly more shadow boundary problems, but what ya gonna do?
		shadow_darkness *= cosine_falloff;
	#endif
	
#endif // FLOATING_SHADOW

	float darken= 1.0f;
#ifndef pc
	[predicateBlock]
//	[predicate]
//	[branch]
#endif // !pc

#ifndef BLOB
	#ifndef FLOATING_SHADOW
		if (shadow_darkness > 0.001)		// if maximum shadow darkness is zero (or very very close), don't bother doing the expensive sampling
	#endif // FLOATING_SHADOW
#endif // BLOB
	{
		// calculate depth_bias (the maximum allowed depth_disparity within a single pixel)
		//		depth_bias = maximum_fragment_slope * half_pixel_size
		//      maximum fragment slope is the magnitude of the surface gradient with respect to shadow-space-Z (basically, glancing pixels have high slope)
		//      half pixel size is the distance in world space from the center of a shadow pixel to a corner (dotted line in diagram)
		//          ___________
		//         |         .'|
		//         |       .'  |
		//         |     .'    |
		//         |           |
		//         |___________|
		//
		//		the basic idea is:  we know the current fragment is within half_pixel_size of the center of this pixel in the shadow projection
		//							the depth map stores the Z value of the center of the pixel, we want to determine what the Z value is at our projection
		//							our simple approximation is to assume it is at the farthest point in the pixel, and do the compare at that point

#ifndef FASTER_SHADOWS
		cosine= max(cosine, 0.24253562503633297351890646211612);									// limits max slope to 4.0, and prevents divide by zero  ###ctchou $REVIEW could make this (4.0) a shader parameter if you have trouble with the masterchief's helmet not shadowing properly
		float slope= sqrt(1-cosine*cosine) / cosine;												// slope == tan(theta) == sin(theta)/cos(theta) == sqrt(1-cos^2(theta))/cos(theta)
		slope= slope + 0.2f;
		float half_pixel_size= SHADOW_PIXELSIZE;													// the texture coordinate distance from the center of a pixel to the corner of the pixel
		float depth_bias = slope * half_pixel_size;
#else
		float depth_bias = 0.001;
#endif // FASTER_SHADOWS


#ifndef	FLOATING_SHADOW
		fragment_shadow_projected.z = min(fragment_shadow_projected.z, 0.99); // allow for shadowing of pixels behind 1.0
#endif

		// sample shadow depth (0.0 is shadowed)
		float percentage_closer= SAMPLE_PERCENTAGE_CLOSER(fragment_shadow_projected.xyz, depth_bias, pixel_pos);
		
       // compute darkening
#ifndef SHADOW_APPLY_JUST_USE_FETCH_RESULT
       darken= saturate(1.01-shadow_darkness + percentage_closer * shadow_darkness);       // 1.001 to fix round off error..  (we want to ensure we output at least 1.0 when percentage_closer= 1, not 0.9999)
       darken*= darken;
#else
       darken = percentage_closer;
#endif // SHADOW_APPLY_JUST_USE_FETCH_RESULT
	}
	
#ifdef FLOATING_SHADOW	
	return float4(darken, darken, 1, darken);
#else
	// [adamgold 3/1/12]  use color write enable to choose whether to render to red (floating shadow) or to green/alpha (object shadow)
	return float4(darken, DIRECT_KNOCKOUT_FACTOR + darken, darken, 0);
#endif
}


// albedo for ambient blur shadow
void albedo_vs(
	in s_tiny_position_vertex input,
	out float4 screen_position : SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_tiny_position, input, output, local_to_world_transform, screen_position);
}


#if defined(xenon)

#include "shadow_apply_registers.fxh"


#define		SPHERE_DATA(index, offset, registers)	occlusion_spheres[index + offset].registers
#define		SPHERE_CENTER(index)			SPHERE_DATA(index, 0, xyz)
#define		SPHERE_AXIS(index)				SPHERE_DATA(index, 1, xyz)
#define		SPHERE_RADIUS_SHORTER(index)	SPHERE_DATA(index, 0, w)
#define		SPHERE_RADIUS_LONGER(index)		SPHERE_DATA(index, 1, w)

float4 albedo_ps(in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target
{
	// get world position of current pixel
	pixel_pos.xy += ps_tiling_vpos_offset.xy;
	
	
#if !defined(xenon)
#if DX_VERSION == 9
	float2 texture_pos= pixel_pos.xy;
	float pixel_depth= sample2D(zbuffer, texture_pos).r;
	float4 normalSample = sample2DLOD(normal_buffer, texture_pos.xy, 0, false);
#elif DX_VERSION == 11
	int3 texture_pos = int3(pixel_pos.xy, 0);
	float pixel_depth = zbuffer.t.Load(texture_pos).x;
	float2 normalSample = normal_buffer.t.Load(texture_pos).xy;
#endif
#else
    float pixel_depth;
	float2 normalSample;
    asm
    {
       tfetch2D pixel_depth.x___, pixel_pos, zbuffer, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD=false
       tfetch2D normalSample.xy__, pixel_pos, normal_buffer, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD=false
    };
#endif

	float4 world_position= float4(transform_texcoord(pixel_pos.xy, screen_xform), pixel_depth, 1.0f);
//	world_position= mul(world_position, transpose(view_inverse_matrix));		// ###ctchou $TODO this is much more optimal
	world_position= mul(world_position, view_inverse_matrix);
	world_position.xyz/= world_position.w;

	float percentage_closer= 1.0f;
	[loop]
	for (int sphere_index= 0; sphere_index < occlusion_spheres_count; sphere_index++)
	{
		//float3 sphere_center= SPHERE_CENTER(sphere_index);
		float3 ellipse_center= SPHERE_CENTER(sphere_index);
		float3 ellipse_axis= SPHERE_AXIS(sphere_index);
		float ellipse_radius_shorter= SPHERE_RADIUS_SHORTER(sphere_index);
		float ellipse_radius_longer= SPHERE_RADIUS_LONGER(sphere_index);

		float3 center_to_pixel_direction= ellipse_center-world_position.xyz;
		float center_to_pixel_distance= length(center_to_pixel_direction);

		// darken by distance along light path
		float darken= 0.0f;
		{
			float3 light_to_cent= cross(center_to_pixel_direction, SHADOW_DIRECTION_NORMALSPACE);
			float light_to_cent_length= length(light_to_cent);

			// normalize light to center vector
			light_to_cent/= light_to_cent_length;
			float along_axis= abs( dot(light_to_cent, ellipse_axis) );
			float radius= lerp(ellipse_radius_shorter, ellipse_radius_longer, along_axis);

			// compute darken
			float ratio= max(light_to_cent_length / radius, 0.5f);
			//ratio= sqrt(ratio);
			darken= saturate( 1.0f - 0.3f * ratio);
		}

		// influence by distance and normal direction
		float influence= 0.0f;
		{
			// normalize direction
			center_to_pixel_direction/= center_to_pixel_distance;
			float radius= ellipse_radius_shorter;

			// compute influence
			//influence= saturate(radius / center_to_pixel_distance);
			influence= saturate(1.0f - 0.2f * center_to_pixel_distance / radius);
			//influence*= influence;

			float avoid_self_shadow= saturate(-0.2f + 1.2f*dot(center_to_pixel_direction, SHADOW_DIRECTION_NORMALSPACE));
			influence*= avoid_self_shadow ;
		}

		//percentage_closer= min(percentage_closer, 1.0f - darken * influence);
		percentage_closer*= 1.0f - darken * influence;
	}

#ifdef xenon	
	float3 normal_world_space= DecodeNormalSigned(normalSample.xy);
#else
	float3 normal_world_space= DecodeNormal(normalSample.xy);
#endif
	float cosine= dot(normal_world_space, SHADOW_DIRECTION_NORMALSPACE.xyz);
	float shadow_darkness= ps_constant_shadow_alpha.r * saturate(0.6f + 0.4f * cosine);			// z_depth_falloff= 1 - (shifted_depth)^4,    incident_falloff= cosine lobe

	//float shadow_darkness= k_ps_constant_shadow_alpha.r * 0.8;


	float darken= 1.0f;
	if (shadow_darkness > 0.001)		// if maximum shadow darkness is zero (or very very close), don't bother doing the expensive PCF sampling
	{
		// compute darkening
		darken= saturate(1.01-shadow_darkness + percentage_closer * shadow_darkness);		// 1.001 to fix round off error..  (we want to ensure we output at least 1.0 when percentage_closer= 1, not 0.9999)
		darken*= darken;
	}

	// compute inscatter
	float3 inscatter= -pixel_depth * INSCATTER_SCALE + INSCATTER_OFFSET;

	// the destination contains (pixel * extinction + inscatter) - we want to change it to (pixel * darken * extinction + inscatter)
	// so we multiply by darken (aka src alpha), and add inscatter * (1-darken)
	return apply_exposure(float4(inscatter * ps_view_exposure.rrr, darken));		// Note: the (inscatter*(1-darken)) clamping is not correct, but only when the inscatter is HDR already - in which case you can't see anything anyways
	// ###ctchou $PERF multiply inscatter by g_exposure before passing to this shader  :)
}

#else

float4 albedo_ps() : SV_Target
{
	return apply_exposure(float4(0.0f, 0.0f, 0.0f, 0.0f));
}

#endif


BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


BEGIN_TECHNIQUE albedo
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(albedo_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}

