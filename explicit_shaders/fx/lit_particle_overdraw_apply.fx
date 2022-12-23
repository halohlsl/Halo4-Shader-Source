
#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "lit_particle_overdraw_apply_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
	float4 light_direction:	TEXCOORD1;		// light direction and alpha
};


#ifdef pc	// --------- pc -------------------------------------------------------------------------------------
s_screen_vertex_output default_vs(
	s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.texcoord=	input.texcoord;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.light_direction.xyzw= 1.0f;
	return output;
}
#else		// --------- xenon ----------------------------------------------------------------------------------
s_screen_vertex_output default_vs(in uint index : SV_VertexID)
{
	s_screen_vertex_output output;

	float	quad_index=		floor(index / 4);						//		[0,	x*y-1]
	float	quad_vertex=	index -	quad_index * 4;					//		[0, 2]

	float2	quad_coords;
	quad_coords.y=	floor(quad_index * quad_tiling.y);				//		[0, y-1]
	quad_coords.x=	quad_index - quad_coords.y * quad_tiling.x;		//		[0, x-1]
		
	float2	subquad_coords;
	subquad_coords.y=	floor(quad_vertex / 2);						//		[0, 1]
	subquad_coords.x=	quad_vertex - subquad_coords.y * 2;			//		[0, 1]
	
	if (subquad_coords.y > 0)
	{
		subquad_coords.x= 1-subquad_coords.x;
	}
	
	quad_coords += subquad_coords;

	// build interpolator output

	output.position.xy=		quad_coords * position_transform.xy + position_transform.zw;
	output.position.zw=		1.0f;

	output.texcoord=			quad_coords * texture_transform.xy + texture_transform.zw;
	
	float2 screen_coords=	quad_coords * quad_tiling.yw;

	// convert world_space_light to relative direction at that pixel...
	float3 camera_space_pixel_vector=	float3(screen_coords * tangent_transform.xy + tangent_transform.zw, 1.0f);
	float3x3 rotation=			NormalizeRotationMatrixFromVectors(float3(1.0f, 0.0f, 0.0f), float3(0.0f, 1.0f, 0.0f), camera_space_pixel_vector, false);
	output.light_direction.xyz=	normalize(mul(transpose(rotation), camera_space_light.xyz));
	
	output.light_direction.a=		saturate(-output.light_direction.z);
					//saturate(dot(normalize(-camera_space_pixel_vector.xyz), normalize(camera_space_light.xyz)));

	output.light_direction.a	*=	output.light_direction.a;
	output.light_direction.a	*=	output.light_direction.a;
	output.light_direction.a	*=	output.light_direction.a;
	
	return output;
}
#endif		// --------- xenon ----------------------------------------------------------------------------------


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float4 color;
#ifdef pc
 	color= sample2D(ps_source_sampler, input.texcoord);
#else // xenon

	float2 texcoord0= input.texcoord;
	float4 tex0, tex1;
	asm
	{
		tfetch2D tex0, texcoord0, ps_source_sampler, MagFilter = linear, MinFilter = linear, MipFilter = point, AnisoFilter = disabled
		tfetch2D tex1, texcoord0, ps_source_lowres_sampler, MagFilter = linear, MinFilter = linear, MipFilter = point, AnisoFilter = disabled
	};

//	float backlit=	saturate(-input.light_direction.z);
//	backlit *= backlit;
//	backlit *= backlit;
//	backlit *= backlit * tex0.a;

	tex0.xy= tex0.rg * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f);
	tex1.xy= tex1.rg * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f);

	[isolate]
	{
		
		float3 vec;
		vec.xy= tex0.xy + light_params.x * tex1.xy;
		vec.z= light_params.y * (1.0f - tex0.a) * (1.0f - tex1.a) * (1.0 - saturate(dot(tex0.xy, tex0.xy)));
		vec.xyz= normalize(vec.xyz);
	
		float lit= dot(vec.xyz, input.light_direction.xyz);			// + 1.5f * darken * darken - 1.3f;
	
		// analytic lighting
//		color.rgb= p_lighting_constant_8.rgb * saturate(lit * light_spread.x + light_spread.y) * tex0.b +		// * saturate(lit * 0.50f + 0.50f) 
//				   p_lighting_constant_9.rgb * saturate(lit * light_spread.z + light_spread.w); 
	
		// palette based lighting
		float4 palette=	sample2D(ps_palette_sampler, float2(lit * 0.5f + 0.5f, tex0.b));
		color.rgb= palette.rgb * (p_lighting_constant_9.rgb + palette.a * p_lighting_constant_8.rgb);
	
		color.rgb= color.rgb * (1.0f - tex0.a);
		color.a= tex0.a;

	}
	
#endif	
 	return color * ps_scale;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



