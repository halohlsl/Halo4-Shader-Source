#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "lens_flare_registers.fxh"


#define center centerRotation.xy
#define rotation centerRotation.z

#define flareOrigin flareOrigin_offsetBounds.xy
#define offsetMin flareOrigin_offsetBounds.z
#define offsetMax flareOrigin_offsetBounds.w

#define scale ps_scale

struct VertexOutput
{
    float4 position : SV_Position;
    float2 texcoord : TEXCOORD0;
};

VertexOutput DefaultVS(const in s_screen_vertex input)
{
	VertexOutput output;

	float sinTheta, cosTheta;
	sincos(rotation, sinTheta, cosTheta);

	float2 scaledPosition = input.position.xy * flareScale.xy;
	output.position.x = dot(float2(cosTheta, sinTheta), scaledPosition);
	output.position.y = dot(float2(-sinTheta, cosTheta), scaledPosition);
	output.position.xy *= flareScale.zw;
	
	output.position.xy = output.position.x * transformedAxes.xy + output.position.y * transformedAxes.zw;
	
	float2 centerOffset = center;
	
	[branch]
	if (offsetMin > 0 || offsetMax > 0)
	{
		float2 offsetFromFlare = centerOffset - flareOrigin;
		float offsetLength = length(offsetFromFlare);
		offsetFromFlare *= clamp(offsetLength, offsetMin, offsetMax) / offsetLength;
		centerOffset = flareOrigin + offsetFromFlare;
	}
	
	output.position.xy += centerOffset;
	
	if (mirrorReflectionAcrossFlare)
	{
		output.position.xy += 2.0 * (flareOrigin - output.position.xy);
	}

	output.position.zw = 1.0f;
	output.texcoord = input.texcoord;
	
	return output;
}

float4 DefaultPS(
	in float4 screenPosition : SV_Position,
	in float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = sample2D(sourceSampler, texcoord);
	float4 colorToNth = pow(color.g, modulationFactor.y); // gamma-enhanced monochrome channel to generate 'hot' white centers
 	
	float4 outColor = (colorToNth * modulationFactor.x) + (color * tintColor); // color tinted external areas for cool exterior
	
	float brightness = tintColor.a * ps_alt_exposure.g * scale.r * modulationFactor.z;
	return outColor * brightness;
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(DefaultVS());
		SET_PIXEL_SHADER(DefaultPS());
	}
}