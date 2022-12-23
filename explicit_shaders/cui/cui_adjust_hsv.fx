#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_hueScaleBiasLerp			k_cui_pixel_shader_color0
#define k_saturationScaleBiasLerp	k_cui_pixel_shader_color1
#define k_valueScaleBiasLerp		k_cui_pixel_shader_color2

#define k_hueClampRange				k_cui_pixel_shader_color3
#define k_saturationClampRange		k_cui_pixel_shader_color4
#define k_valueClampRange			k_cui_pixel_shader_color5


float MinChannel(float3 color)
{
    return min(min(color.r, color.g), color.b);
}

float MaxChannel(float3 color)
{
    return max(max(color.r, color.g), color.b);
}

float3 RGBToHSV(float3 rgb)
{
	float3 hsv = (0).xxx;

	float minVal = MinChannel(rgb);
	float maxVal = MaxChannel(rgb);
	float delta = maxVal - minVal;

	hsv.z = maxVal;
	if (delta != 0)
	{
		hsv.y = delta / maxVal;

		float3 delRgb;
		delRgb = (((maxVal.xxx - rgb) / 6.0) + (delta * 0.5) ) / delta;

		if (rgb.x == maxVal)
		{
			hsv.x = frac(delRgb.z - delRgb.y);
		}
		else if (rgb.y == maxVal)
		{
			hsv.x = frac((1.0/3.0) + delRgb.x - delRgb.z);
		}
		else // if (rgb.z == maxVal)
		{
			hsv.x = frac((2.0/3.0) + delRgb.y - delRgb.x);
		}
	}

	return hsv;
}

float3 HSVToRGB(float3 hsv)
{
	float3 rgb = hsv.z;
	if (hsv.y != 0)
	{
		float var_h = hsv.x * 6;
		float var_i = floor(var_h);
		float var_1 = hsv.z * (1.0 - hsv.y);
		float var_2 = hsv.z * (1.0 - hsv.y * (var_h-var_i));
		float var_3 = hsv.z * (1.0 - hsv.y * (1-(var_h-var_i)));

		if (var_i == 0)			{ rgb = float3(hsv.z, var_3, var_1); }
		else if (var_i == 1)	{ rgb = float3(var_2, hsv.z, var_1); }
		else if (var_i == 2)	{ rgb = float3(var_1, hsv.z, var_3); }
		else if (var_i == 3)	{ rgb = float3(var_1, var_2, hsv.z); }
		else if (var_i == 4)	{ rgb = float3(var_3, var_1, hsv.z); }
		else					{ rgb = float3(hsv.z, var_1, var_2); }
	}
	return rgb;
}

float AdjustComponent(float input, float4 adjustment, float4 clampRange)
{
	// Scale-bias the input based on adjustment.xy
	input = (input * adjustment.x) + adjustment.y;

	// Blend between [0 .. input .. 1] as adjustment.z goes from [0 .. 0.5 .. 1]
	const float blendFactor = saturate(adjustment.z);
	input = lerp(0.0, input, saturate(blendFactor * 2.0)) +
		lerp(0.0, 1.0-input, saturate((blendFactor - 0.5) * 2.0));

	return max(min(input, clampRange.y), clampRange.x);
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color = cui_tex2D(input.texcoord);
	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));

	// Remove the alpha from the rgb channels
	color.rgb /= max(1.0 - color.a, 1.0 / 256.0);
	color.rgb = saturate(color.rgb);

	float3 hsv = RGBToHSV(color.rgb);

	hsv.x = AdjustComponent(hsv.x, k_hueScaleBiasLerp, k_hueClampRange);
	hsv.y = saturate(AdjustComponent(hsv.y, k_saturationScaleBiasLerp, k_saturationClampRange));
	hsv.z = saturate(AdjustComponent(hsv.z, k_valueScaleBiasLerp, k_valueClampRange));

	color.rgb = HSVToRGB(hsv) * (1.0 - color.a);

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

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
