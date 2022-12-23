#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

#include "chud_util.fxh"

#define LDR_ONLY
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b

#define k_blackPoint 0.47
#define k_whitePoint 0.80
#define k_alphaAdjustScale 2.0
#define k_alphaAdjustBase 1.5

//@generate chud_simple

// ==== SHADER DOCUMENTATION
// shader: chud_simple
// 
// ---- COLOR OUTPUTS
// color output A= solid color
// color output B= unused
// color output C= unused
// color output D= unused
// 
// ---- SCALAR OUTPUTS
// scalar output A= unused
// scalar output B= unused
// scalar output C= unused
// scalar output D= unused
// scalar output E= unused
// scalar output F= unused

// ---- BITMAP CHANNELS
// A: alpha
// R: unused
// G: selects between primary (0) and secondary (255) color
// B: highlight channel

LOCAL_SAMPLER2D(damage_sampler, 1);

chud_output default_vs(
	const in s_chud_vertex_simple IN)
{
    chud_output OUT;

    float3 virtual_position= chud_local_to_virtual(IN.position.xy);

    float3 virtual_position_unity= float3(
		virtual_position.x/chud_screen_size.z,
		virtual_position.y/chud_screen_size.w,
		virtual_position.z);
    
	//OUT.VirtualPos= float4(virtual_position_unity, 0);
	float4 hposition=	chud_virtual_to_screen(virtual_position);
    OUT.HPosition=		hposition;
    OUT.MicroTexcoord=	(IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw);
	OUT.Texcoord=		(float2(hposition.x + 0.5, 1.0 - (hposition.y + 0.5)) - chud_screenshot_info.zw / chud_screen_size.xy) / chud_screenshot_info.xy;

    return OUT;
}

// pixel fragment entry points
float4 default_ps(
	const in chud_output IN) : SV_Target
{
	float4 microTexture = sample2D(basemap_sampler, IN.MicroTexcoord);
	float4 damageBlend = sample2D(damage_sampler, IN.Texcoord);
	damageBlend.rgb	*= damageBlend.rgb;

	float pseudoAlpha = (microTexture.g - k_blackPoint) / (k_whitePoint - k_blackPoint);
	pseudoAlpha = (pseudoAlpha * k_alphaAdjustScale) + k_alphaAdjustBase;

	// ###ctchou $NOTE : the * 8 is to make it backwards compatible with the old render that was assuming we were writing to the HDR target where the white point is at 1/8
	// now we are writing to the final render target with the white point at 1.0, so we have to multiply by 8 to make it exactly the same as before (See bug 37459)
	float4 result = float4(
		damageBlend.rgb * microTexture.rgb * float3(microTexture.aaa * 8),
		pseudoAlpha * damageBlend.a * microTexture.a);
		
#if DX_VERSION == 11		
	result = saturate(result);
#endif

	return result;
}


BEGIN_TECHNIQUE _default
{
	pass chud_simple
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}