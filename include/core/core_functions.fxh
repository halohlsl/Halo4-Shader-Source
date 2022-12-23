#if !defined(__CORE_FUNCTIONS_FXH)
#define __CORE_FUNCTIONS_FXH


#if !defined(DEFAULT_TEXTURE_GAMMA)
#error DEFAULT_TEXTURE_GAMMA must be defined!
#endif

#if !defined(DEFAULT_OUTPUT_GAMMA)
#define DEFAULT_OUTPUT_GAMMA 1.0/DEFAULT_TEXTURE_GAMMA
#endif

#include "operations/color.fxh"
#include "operations/normal.fxh"
#include "core/core_math.fxh"

#if !defined(xenon) && !defined(pc)
#define NORMALMAPS_REQUIRE_BIAS
#endif


// basic transformation function
float3 transform_point(const in float4 p, const in float4 transform[3])
{
	float3 result;
	result.x= dot(p, transform[0]);
	result.y= dot(p, transform[1]);
	result.z= dot(p, transform[2]);
	return result;
}

float3 transform_vector(const in float3 v, const in float4 transform[3])
{
	float3 result;
	result.x= dot(v, transform[0].xyz);
	result.y= dot(v, transform[1].xyz);
	result.z= dot(v, transform[2].xyz);
	return result;
}

float2 transform_texcoord(in float2 texcoord, in float4 transform)
{
	return texcoord * transform.xy + transform.zw;
}

void transform_identity(out float4 identity_transform[3])
{
	identity_transform[0]= float4(1, 0, 0, 0);
	identity_transform[1]= float4(0, 1, 0, 0);
	identity_transform[2]= float4(0, 0, 1, 0);
}

// safe normalize function that returns 0 for zero length vectors (360 normalize does this by default)
float3 safe_normalize(in float3 v)
{
#ifdef xenon
	return normalize(v);
#else
	float l = dot(v,v);
	if (l > 0)
	{
		return v * rsqrt(l);
	} else
	{
		return 0;
	}
#endif
}

// safe sqrt function that returns 0 for inputs that are <= 0
float safe_sqrt(in float x)
{
	return (x <= 0) ? 0 : sqrt(x);
}

///////////////////////////////////////////////////////////////////////////////
/// Lambert azimuthal equal-area projection
/// http://en.wikipedia.org/wiki/Lambert_azimuthal_equal-area_projection

#pragma warning(disable : 4118)			// we assume that the vector coming in is normalized, so prevent warnings/errors with negative sqrt

float2 EncodeWorldspaceNormal(float3 normal)
{
#if defined(xenon) || (DX_VERSION == 11)
	normal = normalize(mul(normal, ps_worldspace_normal_axis));
	float rescale = safe_sqrt(normal.z * 8.0 + 8.0);
#if DX_VERSION == 11
	if (rescale > 0.0)
#endif	
	{
		normal.xy /= rescale;
	}
	return normal.xy + (512.0/1023.0);
    //return float2(normal.xy / rescale + 512.0/1023.0);
#else
	return float2(0.5, 0.5);
#endif
}

float3 DecodeNormalSigned(float2 encodedNormal)
{
#if defined(xenon) || (DX_VERSION == 11)
	float2 expanded = encodedNormal;
	float f = dot(expanded, expanded);
	float2 g = float2(4.0 - 4.0 * f, 1.0 - 2.0 * f); // this formulation seems to save us 2 cycles in the shadow apply shader
	return float3(expanded * safe_sqrt(g.x), g.y);
#else
	return float3(0, 0, 1);
#endif
}

float3 DecodeNormal(float2 encodedNormal)
{
	return DecodeNormalSigned((encodedNormal * 2.0) - 1.0);
}

float3 DecodeWorldspaceNormal(float2 encodedNormal)
{
#if defined(xenon) || (DX_VERSION == 11)
	float2 expanded = (encodedNormal - 512.0/1023.0);
	float f = dot(expanded, expanded);
	float2 g = float2(-0.25 * 16.0, -0.5) * 16.0 * f + float2(16.0, 1.0);
	float3 normal = float3(expanded * safe_sqrt(g.x), g.y);
	return mul(ps_worldspace_normal_axis, normal);
#else
	return float3(0, 0, 1);
#endif
}

float3 DecodeWorldspaceNormalSigned(float2 encodedNormal)
{
#if defined(xenon)|| (DX_VERSION == 11)
	float2 expanded = encodedNormal;
	float f = dot(expanded, expanded);
	float2 g = float2(-0.25 * 4.0, -0.5) * 4.0 * f + float2(4.0, 1.0);
	float3 normal = float3(expanded * safe_sqrt(g.x), g.y);
	return mul(ps_worldspace_normal_axis, normal);
#else
	return float3(0, 0, 1);
#endif
}

#pragma warning(default : 4118)			// restore warnings

///////////////////////////////////////////////////////////////////////////////

float3 CombineTangentSpaceNormals(in float3 normal1, in float3 normal2)
{
	float3 combinedNormal = normal1 + normal2;
	combinedNormal.z = sqrt(saturate(1.0f + dot(combinedNormal.xy, -combinedNormal.xy)));
	return combinedNormal;
}

float GetLinearColorIntensity(in float3 linearColor)
{
	return dot(linearColor, float3(0.3086f, 0.6094f, 0.0820f));
}

float3 DesaturateLinearColor(in float3 linearColor, in float desaturation)
{
	return lerp(linearColor, GetLinearColorIntensity(linearColor), desaturation);
}

float GetGammaColorIntensity(in float3 gammaColor)
{
	return dot(gammaColor, float3(0.299f, 0.587f, 0.114f));
}

float3 DesaturateGammaColor(in float3 gammaColor, in float desaturation)
{
	return lerp(gammaColor, GetGammaColorIntensity(gammaColor), desaturation);
}

float4 ApplyTextureGamma(float4 value, uniform bool ApplyGamma = true)
{
#if !defined(HARDWARE_TEXTURE_GAMMA)
	if (ApplyGamma)
	{
		value = saturate(value);
		value.rgb = pow(value.rgb, DEFAULT_TEXTURE_GAMMA);
	}
#endif
	return value;
}

// sampler1D helper functions
float4 sample1D(texture_sampler_1d s, float u, uniform bool ApplyGamma = false)
{
#if DX_VERSION == 9
	float4 value = tex1D(s, u);
#elif DX_VERSION == 11
	float4 value = s.t.Sample(s.s, u);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float4 sample1DGamma(texture_sampler_1d s, float u)
{
	return sample1D(s, u, true);
}

float3 sample1DVector(texture_sampler_1d s, float u)
{
	float3 value = sample1D(s, u).xyz;

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sample1DNormal(texture_sampler_1d s, float u)
{
	float3 normal = sample1DVector(s, u);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}

float3 sample1DNormal_approx(texture_sampler_1d s, float u)
{
	float3 normal = sample1DVector(s, u);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#endif

	return normal;
}


float4 sample2D(texture_sampler_2d s, float2 uv, uniform bool ApplyGamma = false)
{
#if DX_VERSION == 9
	float4 value = tex2D(s, uv);
#elif DX_VERSION == 11
	float4 value = s.t.Sample(s.s, uv);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float4 sample2DGamma(texture_sampler_2d s, float2 uv)
{
	float4 value = sample2D(s, uv, true);
	return value;
}

float4 sample2DLOD(texture_sampler_2d s, float2 uv, float lod, uniform bool ApplyGamma = true)
{
#if DX_VERSION == 9
	float4 value = tex2Dlod(s, float4(uv, 0, lod));
#elif DX_VERSION == 11
	float4 value = s.t.SampleLevel(s.s, uv, lod);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float3 sample2DVector(texture_sampler_2d s, float2 uv)
{
	float3 value = sample2D(s, uv).xyz;

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sample2DNormal(texture_sampler_2d s, float2 uv)
{
	float3 normal = sample2DVector(s, uv);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}


float3 sample_2d_normal_approx(texture_sampler_2d s, float2 uv)
{
	float3 normal = sample2DVector(s, uv);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#endif

	return normal;
}



float3 sample2DNormalToColor(texture_sampler_2d s, float2 uv){
	float3 normal = sample_2d_normal_approx(s, uv);
	normal_deexpand(normal);
	return normal;
}



// sampler3D helper functions

float4 sample3D(texture_sampler_3d s, float3 uvw, uniform bool ApplyGamma = false)
{
#if DX_VERSION == 9
	float4 value = tex3D(s, uvw);
#elif DX_VERSION == 11
	float4 value = s.t.Sample(s.s, uvw);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float4 sample3DGamma(texture_sampler_3d s, float3 uvw)
{
	float4 value = sample3D(s, uvw, true);
	return value;
}

float4 sample3DLOD(texture_sampler_3d s, float3 uvw, float lod, uniform bool ApplyGamma = true)
{
#if DX_VERSION == 9
	float4 value = tex3Dlod(s, float4(uvw, lod));
#elif DX_VERSION == 11
	float4 value = s.t.SampleLevel(s.s, uvw, lod);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float3 sample3DVector(texture_sampler_3d s, float3 uvw)
{
	float3 value = sample3D(s, uvw).xyz;

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sample3DNormal(texture_sampler_3d s, float3 uvw)
{
	float3 normal= sample3DVector(s, uvw);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}

float3 sample3DNormal_approx(texture_sampler_3d s, float3 uvw)
{
	float3 normal= sample3DVector(s, uvw);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#endif

	return normal;
}

#if DX_VERSION == 11
float4 sample3D(texture_sampler_2d_array s, float3 uvw, uniform bool ApplyGamma = false)
{
	float4 value = s.t.Sample(s.s, uvw);
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float4 sample3DGamma(texture_sampler_2d_array s, float3 uvw)
{
	float4 value = sample3D(s, uvw, true);
	return value;
}

float4 sample3DLOD(texture_sampler_2d_array s, float3 uvw, float lod, uniform bool ApplyGamma = true)
{
	float4 value = s.t.SampleLevel(s.s, uvw, lod);
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float3 sample3DVector(texture_sampler_2d_array s, float3 uvw)
{
	float3 value = sample3D(s, uvw).xyz;

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sample3DNormal(texture_sampler_2d_array s, float3 uvw)
{
	float3 normal= sample3DVector(s, uvw);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}

float3 sample3DNormal_approx(texture_sampler_2d_array s, float3 uvw)
{
	float3 normal= sample3DVector(s, uvw);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#endif

	return normal;
}
#endif

// samplerCUBE helper functions
float4 sampleCUBE(texture_sampler_cube s, float3 uv, uniform bool ApplyGamma = false)
{
#if DX_VERSION == 9
	float4 value = texCUBE(s, uv);
#elif DX_VERSION == 11
	float4 value = s.t.Sample(s.s, uv);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float4 sampleCUBEGamma(texture_sampler_cube s, float3 uv)
{
#if DX_VERSION == 9
	float4 value= texCUBE(s, uv);
#elif DX_VERSION == 11
	float4 value = s.t.Sample(s.s, uv);
#endif
	ApplyTextureGamma(value, true);
	return value;
}

float4 sampleCUBELOD(texture_sampler_cube s, float3 uv, float lod, uniform bool ApplyGamma = true)
{
#if DX_VERSION == 9
	float4 value = texCUBElod(s, float4(uv, lod));
#elif DX_VERSION == 11
	float4 value = s.t.SampleLevel(s.s, uv, lod);
#endif
	value = ApplyTextureGamma(value, ApplyGamma);
	return value;
}

float3 sampleCUBEVector(texture_sampler_cube s, float3 uv)
{
#if DX_VERSION == 9
	float3 value= texCUBE(s, uv).xyz;
#elif DX_VERSION == 11
	float3 value = s.t.Sample(s.s, uv);
#endif

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sampleCUBENormal(texture_sampler_cube s, float3 uv)
{
	float3 normal= sampleCUBEVector(s, uv);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}

float3 sampleCUBENormal_approx(texture_sampler_cube s, float3 uv)
{
	float3 normal= sampleCUBEVector(s, uv);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#endif

	return normal;
}



float3x3 get_tangent_frame(const in s_pixel_shader_input pixel_shader_input)
{
#if !defined(DISABLE_TANGENT_FRAME)
	float3x3 tangent_frame= {pixel_shader_input.tangent.xyz, pixel_shader_input.binormal.xyz, pixel_shader_input.normal.xyz};
#elif !defined(DISABLE_NORMAL)
	float3x3 tangent_frame= {float3(1,0,0), float3(0,1,0), pixel_shader_input.normal.xyz};
#else
	float3x3 tangent_frame= {float3(1,0,0), float3(0,1,0), float3(0,0,1)};
#endif

	return tangent_frame;
}

float3 get_view_vector(const in s_pixel_shader_input pixel_shader_input)
{
#if defined(DISABLE_VIEW_VECTOR)
	return 0;
#else
	return pixel_shader_input.view_vector.xyz;
#endif
}

float3 generate_binormal(float3 normal, float3 tangent, const float binormal_scale)
{
	// derive binormal from normal and tangent plus a flag in position.w
	return binormal_scale * cross(normal, tangent);
}

float4 apply_output_gamma(float4 output)
{
#if !defined(HARDWARE_TEXTURE_GAMMA)
#if !defined(cgfx)
	return pow(max(0.00001, output), DEFAULT_OUTPUT_GAMMA);
#else
	return pow(output, DEFAULT_OUTPUT_GAMMA);
#endif
#else
	return output;
#endif
}

// uses vector k directly, and does a projected least squares fit on i, j.  REQUIRES non-zero, distinct input vectors
float3x3 NormalizeRotationMatrixFromVectors(
	in float3 i,
	in float3 j,
	in float3 k,
	uniform bool inputVectorsNormalized)
{
	if (inputVectorsNormalized == false)
	{
		i = normalize(i);
		j = normalize(j);
		k = normalize(k);
	}

	float3 proj_i =	normalize(i - k * dot(i, k));
	float3 proj_j = normalize(j - k * dot(j, k));

	// midpoint vector
	float3 mid_pij = (proj_i + proj_j) * 0.5f;

	// difference vector  (guaranteed orthogonal to midpoint vector)
	float3 dif_pij = (proj_j - proj_i) * 0.5f;

	//
	// note:		proj_i	==	mid_pij - dif_pij
	//				proj_j	==	mid_pij + dif_pij
	//
	//		What we're gonna do is scale dif_pij so it is the same length as mid_pij.
	//		This makes the new i,j vectors orthogonal (because they're both 45 degrees from the midpoint vector)
	//		and equidistant from their original points.
	//
	dif_pij *= length(mid_pij) / length(dif_pij);

	float3x3 result;
	result[0] = normalize(mid_pij - dif_pij);		// modified projected i
	result[1] = normalize(mid_pij + dif_pij);		// modified projected j
	result[2] = k;

	return result;
}


// - Specular Helper Functions

// convert rougness - 1/0.1 = 10.0
float calc_roughness( float roughness )
{
	return 1/max(0.00001, roughness);
}

// uses a gloss map to drive specular size. min and max set the output white.black point values
float calc_roughness(
			float gloss_map_value,
			float outMin,
			float outMax )
{

	float output = 0;
		// invert gloss map
	gloss_map_value = 1-gloss_map_value;
		// set the white-black point for the gloss map.
	output = float_remap(gloss_map_value, 0, 1, outMin, outMax);
		// convert total roughness - 1/0.1 = 10.0
	return calc_roughness(output);

}

float3 CalcSpecularColor(
	in float3 view,
	in float3 normal,
	in float3 albedoColor,
	in float albedoBlend,
	in float3 specularColor,
	in float3 glancingSpecularColor,
	in float fresnelPower)
{
    float NdotV = saturate(dot(normal, view));
    float fresnelBlend = pow(1.0f - NdotV, fresnelPower);

    float3 basicSpecularColor = lerp(specularColor, albedoColor, albedoBlend);
    return lerp(basicSpecularColor, glancingSpecularColor, fresnelBlend);
}


float3 CompositeDetailNormalMap(
	float3 baseNormal,
	texture_sampler_2d detailNormalSampler,
	float2 detailNormalUV,
	float detailNormalIntensity)
{
	float2 detailNormal = sample2DVector(detailNormalSampler, detailNormalUV);

	baseNormal.xy = baseNormal.xy + detailNormalIntensity * detailNormal.xy;
	baseNormal.z = sqrt(saturate(1.0f + dot(baseNormal.xy, -baseNormal.xy)));

	return baseNormal;
}


// [hcoulby: 3/22/2011] Hack for Vic which I will remove it soon
float3 CompositeDetailNormalMapMACRO(
	const in s_common_shader_data common,
	float3 normal_base,
	texture_sampler_2d normal_detail_sampler,
	float2 normal_detail_uv,
	float normal_detail_dist_min,
	float normal_detail_dist_max,
	float view_invert)
{
	float view = lerp(common.view_dir_distance.w,1-common.view_dir_distance.w, view_invert);

	float lerpAmt = float_remap( view ,
								 normal_detail_dist_min,
								 normal_detail_dist_max,
								 1, 0 );

	return CompositeDetailNormalMap(normal_base, normal_detail_sampler, normal_detail_uv, lerpAmt);
}



float3 CompositeDetailNormalMap(
	const in s_common_shader_data common,
	float3 normal_base,
	texture_sampler_2d normal_detail_sampler,
	float2 normal_detail_uv,
	float normal_detail_dist_min,
	float normal_detail_dist_max)
{
	float lerpAmt = float_remap( common.view_dir_distance.w,
								 normal_detail_dist_min,
								 normal_detail_dist_max,
								 1, 0 );

	return CompositeDetailNormalMap(normal_base, normal_detail_sampler, normal_detail_uv, lerpAmt);
}

// faster component max
float maxcomp(float3 a)
{
#if defined(xenon)
	float4 k;
	asm {
		max4 k.x, a.xyzx;
	};
	return k.x;
#else
	return max(max(a.x, a.y), a.z);
#endif
}

float maxcomp(float4 a)
{
#if defined(xenon)
	float4 k;
	asm {
		max4 k.x, a;
	};
	return k.x;
#else
	return max(max(a.x, a.y), max(a.z, a.w));
#endif
}

// pack and unpack instructions for RGBk, must match c++ code
float3 UnpackRGBk(in float4 c)
{
	return c.rgb * c.a * 31.875;
}

float4 PackRGBk(in float3 c)
{
	// no need to clamp this, it will saturate on output
    float k = floor( maxcomp(c) * 8.0 + 1.0) / 8.0;
    return float4(c.rgb / k, k / 31.875);
}

bool AllowReflection(s_common_shader_data common)
{
	return (common.lighting_mode != LM_DYNAMIC_LIGHTING) ? true : false;
}

bool AllowSelfIllum(s_common_shader_data common)
{
	return (common.lighting_mode != LM_DYNAMIC_LIGHTING) ? true : false;
}

#if DX_VERSION == 11
// convert normalized 3d texture z coordinate to texture array coordinate
float4 Convert3DTextureCoordToTextureArray(in texture_sampler_2d_array t, in float3 uvw)
{
	uint width, height, elements;
	t.t.GetDimensions(width, height, elements);
	
	float half_recip_elements = 0.5f / elements;

	return float4(
		uvw.xy,
		saturate(uvw.zz + float2(-half_recip_elements, half_recip_elements)) * elements);
}

float4 sampleArrayWith3DCoords(in texture_sampler_2d_array t, in float3 uvw)
{
	float4 array_texcoord = Convert3DTextureCoordToTextureArray(t, uvw);
	float frac_z = frac(array_texcoord.z);
	array_texcoord.zw = floor(array_texcoord.zw);
	return lerp(
		sample3D(t, array_texcoord.xyz),
		sample3D(t, array_texcoord.xyw),
		frac_z);
}

float4 sampleArrayWith3DCoordsGamma(in texture_sampler_2d_array t, in float3 uvw)
{
	float4 array_texcoord = Convert3DTextureCoordToTextureArray(t, uvw);
	float frac_z = frac(array_texcoord.z);
	array_texcoord.zw = floor(array_texcoord.zw);
	return lerp(
		sample3DGamma(t, array_texcoord.xyz),
		sample3DGamma(t, array_texcoord.xyw),
		frac_z);
}

// gets x/y gradients in same format as Xenon getGradients instruction (although does not take sampler into account)
float4 GetGradients(in float2 value)
{
	float2 x_gradient = ddx(value);
	float2 y_gradient = ddy(value);
	return float4(x_gradient.x, y_gradient.x, x_gradient.y, y_gradient.y);
}
#endif

#endif 	// !defined(__CORE_FUNCTIONS_FXH)