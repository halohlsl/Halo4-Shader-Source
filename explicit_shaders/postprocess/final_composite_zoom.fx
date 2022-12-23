
#define TEMPORAL_ANTIALIASING


#if defined(xenon)
#define COMBINE_HDR_LDR combine_dof
float4 combine_dof(in float2 texcoord);
#endif // !pc


#define CALC_BLEND calc_blend_weapon_zoom
float3 calc_blend_weapon_zoom(in float2 texcoord, in float4 combined, in float4 bloom);

#include "../postprocess/final_composite_shared.fxh"


float3 calc_blend_weapon_zoom(in float2 texcoord, in float4 combined, in float4 bloom)
{
	float3 blend= combined * bloom.a + bloom.rgb;
	float2 blur_grade_texcoord= (texcoord.xy - ps_player_window_constants.xy) / ps_player_window_constants.zw;
	const float blur_grade= sample2D(ps_blur_grade_sampler, blur_grade_texcoord).b;
	[branch]
	if (blur_grade > 0.01f)
	{
		//float3 blur_color= bloom.rgb * (intensity.z * intensity.x * bloom.a + intensity.y);
		//float3 blur_color= bloom.rgb * (intensity.z * bloom.a + 1);
		float3 blur_color= bloom.rgb * (1 * bloom.a + 1);
		blend= lerp(blend, blur_color, blur_grade);
//		blend= lerp(blend, bloom.rgb * intensity.z, blur_grade);				
		blend= lerp(blend, bloom.rgb * 1, blur_grade);				
	}
	return blend;
}

