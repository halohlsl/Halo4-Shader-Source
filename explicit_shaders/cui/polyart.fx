#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_curvature_transform.fxh"
#include "lighting/specular_models.fxh"
#include "lighting/vmf.fxh"
#include "exposure.fxh"
#include "polyart_registers.fxh"


#define k_specularColor k_cui_pixel_shader_color0
#define k_specularIntensity k_cui_pixel_shader_color1.r
#define k_specularMixAlbedo k_cui_pixel_shader_color1.g
#define k_specularPowerMin k_cui_pixel_shader_color1.b
#define k_specularPowerMax k_cui_pixel_shader_color1.a

#define k_lightAttenuation k_cui_pixel_shader_color2.r
#define k_lightAttenuationPower k_cui_pixel_shader_color2.g
#define k_lightAttenuationConeScale k_cui_pixel_shader_color2.b
#define k_lightAttenuationConeBias k_cui_pixel_shader_color2.a

#define k_lightAttenuationDirectionAngle k_cui_pixel_shader_color3.xyz

struct PolyartVSOutput {
	float4 Pos	: SV_Position;
	float4 Color : COLOR;
};

struct PolyartUvVSOutput
{
	float4 position		: SV_Position;
	float4 color		: COLOR;
	float2 texcoord		: TEXCOORD0;
	float3 viewVector	: TEXCOORD1;
};


float4 default_ps(const in PolyartVSOutput input) : SV_Target
{
	return input.Color;
}

float3 CalcDiffuseLambert(s_vmf_sample_data vmfSampleVertex, float3 normal)
{
	float3 diffuse = 0.0f;

#if defined(xenon) || (DX_VERSION == 11)
	diffuse += VMFDiffuse(
		vmfSampleVertex,
		normal,
		normal,
		1.0f,
		0.0f,
		LM_PROBE);

	// Compute the SH
	diffuse += PerformQuadraticSHCosineConvolution(ps_model_sh_lighting, normal);
#endif

	return diffuse;
}

float4 static_lit_cui_ps(const in PolyartUvVSOutput input) : SV_Target
{
	s_vmf_sample_data vmfSampleVertex;
	sample_lightprobe_constants(vmfSampleVertex);

	float2 texcoord = float2(input.texcoord.x, 1.0 - input.texcoord.y);
	float4 albedoSample = sample2D(sampler0, texcoord);
	float4 specularSample = sample2D(sampler1, texcoord);
	float3 normalScreen = sample2DNormal(sampler2, texcoord).xyz;
	float3 normalWorld = mul(normalScreen, ps_camera_to_world_matrix);

	float scaleBiasedNDotA = saturate(saturate(dot(normalScreen, k_lightAttenuationDirectionAngle)) * k_lightAttenuationConeScale + k_lightAttenuationConeBias);
	float lightAttenuation = 1.0f - (pow(scaleBiasedNDotA, k_lightAttenuationPower) * k_lightAttenuation);

	s_common_shader_data common = (s_common_shader_data)0;
	common.lighting_mode = LM_PROBE;
	common.normal = normalWorld;
	common.geometricNormal = normalWorld;
	common.lighting_data.shadow_mask.g = 1.0;
	common.lighting_data.savedAnalyticScalar = 0.0;
	common.lighting_data.vmf_data = vmfSampleVertex;
	common.view_dir_distance.xyz = input.viewVector;

	// using lambert diffuse model
	float3 diffuse = CalcDiffuseLambert(vmfSampleVertex, normalWorld);
	diffuse *= albedoSample.rgb * input.color.rgb * lightAttenuation;

	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(specularSample.a, k_specularPowerMin, k_specularPowerMax);

	// using blinn specular model
	float3 specular = 0.0f;
	calc_specular_blinn(specular, common, normalWorld, albedoSample.a, power);

	// mix k_specularColor with albedo_color
	float3 finalSpecularColor = lerp(k_specularColor, albedoSample.rgb, k_specularMixAlbedo);

	// modulate by mask, color, and intensity
	specular *= specularSample.rgb * finalSpecularColor * k_specularIntensity * lightAttenuation;

	float4 litPixel = float4(diffuse + specular, input.color.a);

	// Apply exposure and output
	litPixel = ApplyExposureSelfIllum(litPixel, 0.0f, true);
	return litPixel;
}

PolyartVSOutput polyart_vs(const in s_polyart_vertex input)
{
	PolyartVSOutput output;

	// First step, transform polyart into Cui widget local space
	float3 modelViewPosition = mul(float4(input.position.xyz, 1.0f), modelViewMatrix);
	float4 transformedPos = mul(float4(modelViewPosition, 1.0f), projectionMatrix);
	transformedPos.xy = (transformedPos.xy / transformedPos.w) * widgetBounds * 0.5f;
	transformedPos.xy += widgetBounds * 0.5f;

	// Second step, transform polyart using Cui's transform matrices.
	modelViewPosition = mul(float4(transformedPos.xy, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix);
	output.Pos = mul(float4(modelViewPosition, 1.0f), k_cui_vertex_shader_constant_projection_matrix);

	output.Color = float4(baseColor.rgb, baseColor.a*input.position.w);
	output.Color.rgb *= output.Color.a;
	output.Color.a = 1.0f - output.Color.a;

	return output;
}

PolyartUvVSOutput polyartUV_vs(const in s_polyartUvVertex input)
{
	PolyartUvVSOutput output;

	// First step, transform polyart into Cui widget local space
	float3 modelViewPosition = mul(float4(input.positionAndAlpha.xyz, 1.0f), modelViewMatrix);
	output.viewVector = normalize(modelViewPosition);

	float4 transformedPos = mul(float4(modelViewPosition, 1.0f), projectionMatrix);
	transformedPos.xy = (transformedPos.xy / transformedPos.w) * widgetBounds * 0.5f;
	transformedPos.xy += widgetBounds * 0.5f;

	// Second step, transform polyart using Cui's transform matrices.
	modelViewPosition = mul(float4(transformedPos.xy, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix);
	output.position = mul(float4(modelViewPosition, 1.0f), k_cui_vertex_shader_constant_projection_matrix);
	output.position.z = 1.0;

	output.color = float4(baseColor.rgb, baseColor.a*input.positionAndAlpha.w);
	output.color.rgb *= output.color.a;
	output.color.a = 1.0f - output.color.a;

	output.texcoord = input.texCoord;

	return output;
}

PolyartVSOutput vectorart_vs(const in s_vectorartVertex input)
{
	PolyartVSOutput output;

	float3 modelViewPos = mul(float4(input.positionAndAlpha.xy, 0.0f, 1.0f), modelViewMatrix);
	output.Pos = mul(float4(modelViewPos, 1.0f), k_cui_vertex_shader_constant_projection_matrix);
	output.Color = float4(baseColor.rgb, baseColor.a*input.positionAndAlpha.z);
	output.Color.rgb *= output.Color.a;
	output.Color.a = 1.0f - output.Color.a;

	return output;
}

PolyartVSOutput curved_cui_polyart_vs(
	const in s_polyart_vertex input)
{
	PolyartVSOutput output;

	// First step, transform polyart into Cui widget local space
	float3 modelViewPosition = mul(float4(input.position.xyz, 1.0f), modelViewMatrix);
	float4 position = mul(float4(modelViewPosition, 1.0f), projectionMatrix);
	position.xy = (position.xy / position.w) + float2(1.0f, 1.0f);
	position.xy *= widgetBounds * 0.5f;

	// Second step, transform polyart using Cui's transform matrices.
	position.xyz = mul(float4(position.xy, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix);

	// Convert to screenspace pixel coordinates, with the origin at the top-left of the screen.
	position.y = -position.y;
	position.xy += k_cui_screen_size.xy * 0.5f;

	// Input for chud_virtual_to_screen() needs to be screenspace pixels, where the origin is at the top-left of the
	// screen.
	output.Pos = chud_virtual_to_screen(position.xy);
	output.Color = float4(baseColor.rgb, baseColor.a*input.position.w);
	output.Color.rgb *= output.Color.a;
	output.Color.a = 1.0f - output.Color.a;

	return output;
}

PolyartUvVSOutput curved_cui_polyartUV_vs(
	const in s_polyartUvVertex input)
{
	PolyartUvVSOutput output;

	// First step, transform polyart into Cui widget local space
	float3 modelViewPosition = mul(float4(input.positionAndAlpha.xyz, 1.0f), modelViewMatrix);
	output.viewVector = normalize(modelViewPosition);
	float4 position = mul(float4(modelViewPosition, 1.0f), projectionMatrix);
	position.xy = (position.xy / position.w) + float2(1.0f, 1.0f);
	position.xy *= widgetBounds * 0.5f;

	// Second step, transform polyart using Cui's transform matrices.
	position.xyz = mul(float4(position.xy, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix);

	// Convert to screenspace pixel coordinates, with the origin at the top-left of the screen.
	position.y = -position.y;
	position.xy += k_cui_screen_size.xy * 0.5f;

	// Input for chud_virtual_to_screen() needs to be screenspace pixels, where the origin is at the top-left of the
	// screen.
	output.position = chud_virtual_to_screen(position.xy);
	output.position.z = 1.0;
	output.color = float4(baseColor.rgb, baseColor.a*input.positionAndAlpha.w);
	output.color.rgb *= output.color.a;
	output.color.a = 1.0f - output.color.a;

	output.texcoord = input.texCoord;

	return output;
}

PolyartVSOutput curved_cui_vectorart_vs(
	const in s_vectorartVertex input)
{
	PolyartVSOutput output;

	// Transform to widget local space
	float3 modelViewPos = mul(float4(input.positionAndAlpha.xy, 0.0f, 1.0f), modelViewMatrix);

	// 'position' will be screenspace pixel coordinates, with the origin in the center of the screen, and top-left
	// will be (-halfScreenWidth,+halfScreenHeight).
	float3 position = mul(float4(modelViewPos.xy, 0.0f, 1.0f), k_cui_vertex_shader_constant_model_view_matrix).xyz;

	// Convert to screenspace pixel coordinates, with the origin at the top-left of the screen.
	position.y = -position.y;
	position.xy += k_cui_screen_size.xy * 0.5f;

	// Input for chud_virtual_to_screen() needs to be screenspace pixels, where the origin is at the top-left of the
	// screen.
	output.Pos = chud_virtual_to_screen(position.xy);
	output.Color = float4(baseColor.rgb, baseColor.a*input.positionAndAlpha.z);
	output.Color.rgb *= output.Color.a;
	output.Color.a = 1.0f - output.Color.a;

	return output;
}


BEGIN_TECHNIQUE _default
{
	pass polyart
	{
		SET_VERTEX_SHADER(polyart_vs());
		SET_PIXEL_SHADER(default_ps());
	}

	pass vectorart
	{
		SET_VERTEX_SHADER(vectorart_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass polyart
	{
		SET_VERTEX_SHADER(curved_cui_polyart_vs());
		SET_PIXEL_SHADER(default_ps());
	}

	pass vectorart
	{
		SET_VERTEX_SHADER(curved_cui_vectorart_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE static_lit_cui
{
	pass polyartUV
	{
		SET_VERTEX_SHADER(polyartUV_vs());
		SET_PIXEL_SHADER(static_lit_cui_ps());
	}
}

BEGIN_TECHNIQUE curved_static_lit_cui
{
	pass polyartUV
	{
		SET_VERTEX_SHADER(curved_cui_polyartUV_vs());
		SET_PIXEL_SHADER(static_lit_cui_ps());
	}
}
