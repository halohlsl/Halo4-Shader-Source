#if !defined(__VMF_FXH)
#define __VMF_FXH

#include "core/core.fxh"
#include "lighting/sh.fxh"

#define LIGHT_PACKING_INDEX_HOR ps_forge_lightmap_packing_constant.x
#define LIGHT_PACKING_SIZE ps_forge_lightmap_packing_constant.y
#define LIGHT_PACKING_INDEX_VER ps_forge_lightmap_packing_constant.z
#define LIGHT_PACKING_COMPRESSION_SCALAR ps_forge_lightmap_packing_constant.w

////////////////////////////////////////////////////////////////////////////////
// Applies VMF bandwidth term to inner product
float VMFEvaluateBandwidth(
    in float innerProduct,
    in float vmfBandwidth)
{
    return saturate(innerProduct);
}

////////////////////////////////////////////////////////////////////////////////
// Returns the lobe directional vector for a VMF
float3 VMFGetVector(
    const in s_vmf_sample_data vmfData,
    const in int vmfIndex)
{
	return safe_normalize(vmfData.coefficients[vmfIndex*2].xyz);
}

float VMFGetAnalyticLightScalar(const in s_vmf_sample_data vmfData)
{
	return vmfData.coefficients[1].w;
}

float VMFGetAOScalar(const in s_vmf_sample_data vmfData)
{
	return vmfData.coefficients[3].w;
}

void VMFSetAnalyticLightScalar(inout s_vmf_sample_data vmfData, const in float analyticLightScalar)
{
	vmfData.coefficients[1].w = analyticLightScalar;
}

void VMFSetAnalyticLightScalarFromAirprobe(inout s_vmf_sample_data vmfData)
{
	VMFSetAnalyticLightScalar(vmfData, ps_model_vmf_lighting[1].w);
}

void VMFScaleValues(inout s_vmf_sample_data vmf_data, float scalar)
{
	vmf_data.coefficients[1].rgb *= scalar;
	vmf_data.coefficients[3].rgb *= scalar;
}

float3 LinearSHEvaluate(
	const in s_vmf_sample_data vmfData,
	const in float3 normal,
	const in float3 geoNormal,
	const in int probeIndex,
	const in bool allowSharpen)
{
	return LinearSHIrradianceScalar(normal, vmfData.coefficients[probeIndex*2+0], vmfData.coefficients[probeIndex*2+1].xyz, geoNormal, allowSharpen);
}

float3 LinearSHGetHDRColor(
	const in s_vmf_sample_data vmfData,
	const in int probeIndex)
{
	return vmfData.coefficients[probeIndex*2+1].rgb;
}

////////////////////////////////////////////////////////////////////////////////
// Returns the color of a VMF sample using a custom inner product for a diffuse model
float3 VMFCustomEvaluate(
    const in s_vmf_sample_data vmfData,
    const in float innerProduct,
	const in int vmfIndex)
{
	float vmfIntensity = VMFEvaluateBandwidth(innerProduct, vmfData.coefficients[vmfIndex * 2 + 1].a);

	// [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor *= 1.25
	// This is a pure visual trick that provides a smooth falloff for greater perceived depth
	// of a surface. There is also a compensation factor that scales the intensity to account
	// for energy conservation. This factor needs to be revisted after vertical slice.
	//
	// this macro is defined in core.fxh. compensation factor set in core_<platform>.fxh
	if(ps_bsp_boolean_enable_sharpened_falloff)
	{
		SQUARE_FALLOFF_VMF(vmfIntensity);
	}


	return vmfData.coefficients[vmfIndex * 2 + 1].rgb * vmfIntensity / pi;
}


////////////////////////////////////////////////////////////////////////////////
// Returns the color of a VMF sample using a custom inner product for a specular model
float3 VMFSpecularCustomEvaluate(
    const in s_vmf_sample_data vmfData,
    const in float innerProduct,
    const in int vmfIndex)
{
    float vmfIntensity = max(0.0, innerProduct);
    return vmfData.coefficients[vmfIndex * 2 + 1].rgb * vmfIntensity;
}


////////////////////////////////////////////////////////////////////////////////
// Returns the color of a VMF sample using a custom inner product for a specular model
// Assumes appropriate input such that a range clamp is unnecessary
float3 VMFSpecularCustomEvaluateNoClamp(
    const in s_vmf_sample_data vmfData,
    const in float innerProduct,
    const in int vmfIndex)
{
    float vmfIntensity = innerProduct;
    return vmfData.coefficients[vmfIndex * 2 + 1].rgb * vmfIntensity;
}


////////////////////////////////////////////////////////////////////////////////
// Returns the N·L evaluation of the VMF
float3 VMFDiffuse(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
	const in float3 geoNormal,
	const in float characterShadow,
	const in float floatingShadowAmount,
	const in int lightingMode)
{
	float3 diffuse;

	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE || lightingMode == LM_PER_PIXEL_SIMPLE)
	{
		// Just transfer the irradiance
		diffuse = vmfData.coefficients[0].xyz;
	}
	else
	{
	#if defined(xenon) || (DX_VERSION == 11)
		const float directLightingMinimumForShadows = ps_bsp_lightmap_scale_constants.y;
	#else
		const float directLightingMinimumForShadows = 0.3f;
	#endif
		float shadowterm = saturate(characterShadow + directLightingMinimumForShadows);

		const bool allowSharpen = (lightingMode != LM_PROBE && lightingMode != LM_PROBE_AO && lightingMode != LM_PER_PIXEL_FORGE);
	
		// We now store two linear SH probes
		// [adamgold 2/13/12] now knock out direct with the character shadow (as long as we're not in the sun)
		diffuse = LinearSHEvaluate(vmfData, normal, geoNormal, 0, allowSharpen) * lerp(shadowterm, 1.0f, floatingShadowAmount)
				+ LinearSHEvaluate(vmfData, normal, geoNormal, 1, allowSharpen);
	}

	return diffuse;
}

////////////////////////////////////////////////////////////////////////////////
// Returns the N·L WRAP evaluation of the VMF
float3 wrap_lighting(
            const in s_vmf_sample_data vmfData,
            const in float3 normal,
            const in float wrap,
            const in float vmfIndex)
{

    float3 vmfDir   = VMFGetVector(vmfData, vmfIndex);
    float3 vmfColor = vmfData.coefficients[vmfIndex * 2 + 1].rgb;

    float diffuse   = max(0, (dot(vmfDir, normal) + wrap) / (1 + wrap));
    return vmfColor * diffuse / pi;
}



float3 VMFDiffuseWrap(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float characterShadow,
    const in float floatingShadowAmount,
    const in float wrap,
    const in bool applyShadow)
{
	
#if defined(xenon) || (DX_VERSION == 11)
	const float directLightingMinimumForShadows = ps_bsp_lightmap_scale_constants.y;
#else
	const float directLightingMinimumForShadows = 0.3f;
#endif
	float shadowterm = saturate(characterShadow + directLightingMinimumForShadows);
	
	float3 direct = wrap_lighting(vmfData, normal, wrap, 0);
	float3 indirect = wrap_lighting(vmfData, normal, wrap, 1);
	
	if (applyShadow)
	{
		// [adamgold 2/13/12] now knock out direct with the character shadow (as long as we're not in the sun)
		direct *= lerp(shadowterm, 1.0f, floatingShadowAmount);
	}	

    return (direct + indirect);
}


////////////////////////////////////////////////////////////////////////////////
// Returns the N·L fill evaluation of the VMF

float3 VmfFillLighting(
            const in s_vmf_sample_data vmfData,
            const in float vmf_index,
            const in float3 normal,
            const in float intensity)
{
    float3 lgt_vector   = VMFGetVector(vmfData, vmf_index);
    float ndotl         = dot( lgt_vector, normal);
    float ndotl_inverse = dot(-lgt_vector, normal);

    float fill_amount = intensity * 0.6;
    ndotl_inverse = (1.0f - ndotl_inverse) * (1.0f - fill_amount) + fill_amount;

    float3 output = 0.0f;
    output =
       VMFCustomEvaluate(vmfData, ndotl, vmf_index) +
      (VMFCustomEvaluate( vmfData, ndotl_inverse, vmf_index ) * intensity );

    return output;
}

// vmf entry point for calc_diffuse_lambert_fill
float3 VMFDiffuseFill(
            const in s_vmf_sample_data vmfData,
            const in float3 normal,
            const in float fill_direct,
            const in float fill_indirect)
{

    float3 direct   = VmfFillLighting(vmfData, 0, normal, fill_direct);
    float3 indirect = VmfFillLighting(vmfData, 1, normal, fill_indirect);
    return (direct + indirect);
}


/////////////////////////////////////////////////////////////////////////////
// VMF Simple Skin Shading

float3 ScatterSimple(float ndotl, float3 color, float wrap){
    float3 diffuse_scatter = smoothstep(-wrap,1.0f,ndotl) - smoothstep(0.0f,1.0f,ndotl);
    diffuse_scatter = max(0.0f,diffuse_scatter);
    diffuse_scatter = diffuse_scatter * color;
    return diffuse_scatter;
}

float3 VMFSkinSimple(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 scatter_color,
    const in float wrap)
{


     float intensity = 0.15f;

    // direct lighting
    float3 vmfDir_0       = VMFGetVector(vmfData, 0);
    float3 vmfColor_0     = vmfData.coefficients[0 * 2 + 1].rgb;
    float  vmfIntensity_0 = VMFEvaluateBandwidth( dot(vmfDir_0, normal), vmfData.coefficients[0 * 2 + 1].a );
    SQUARE_FALLOFF_VMF(vmfIntensity_0);
    float3 scatterDirect = ScatterSimple(vmfIntensity_0, scatter_color, wrap);
    float3 direct   = vmfColor_0 * vmfIntensity_0 * (1 + scatterDirect) / pi;


    float ndotl_inverse = dot(-vmfDir_0, normal);
    float fill_amount = max((intensity-0.08f),0.0f);
    ndotl_inverse = (1.0f - ndotl_inverse) * (1.0f - fill_amount) + fill_amount;
    float3 direct_fill = VMFCustomEvaluate( vmfData, ndotl_inverse, 0 ) * intensity;
    direct = direct + direct_fill;

    // indirect lighting
    float3 vmfDir_1       = VMFGetVector(vmfData, 1);
    float3 vmfColor_1     = vmfData.coefficients[1 * 2 + 1].rgb;
    float  vmfIntensity_1 = VMFEvaluateBandwidth( dot(vmfDir_1, normal), vmfData.coefficients[1 * 2 + 1].a );
    SQUARE_FALLOFF_VMF(vmfIntensity_0);
    float3 scatterIndirect = ScatterSimple(vmfIntensity_1, scatter_color, wrap);
    float3 indirect = vmfColor_1 * vmfIntensity_1 * (1 + scatterIndirect)  / pi;

    ndotl_inverse = dot(-vmfDir_1, normal);
    fill_amount = max((intensity-0.08f),0.0f);
    ndotl_inverse = (1.0f - ndotl_inverse) * (1.0f - fill_amount) + fill_amount;
    float3 indirect_fill = VMFCustomEvaluate( vmfData, ndotl_inverse, 1 ) * intensity;
    indirect = indirect + indirect_fill;


    // finalize...
    float3 vmfDiffuse = direct + indirect;


    return vmfDiffuse;
}


/////////////////////////////////////////////////////////////////////////////
// VMF Simple Translucent "Back-Lighting" model

float3 VMFDiffuse_BackLighting(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 view,
    const in float3 translucence)
{
    // direct lighting
    float3 vmfDir_0       = VMFGetVector(vmfData, 0);
    float3 vmfColor_0     = vmfData.coefficients[0 * 2 + 1].rgb;
    float  vmfIntensity_0 = VMFEvaluateBandwidth( dot(vmfDir_0, normal), vmfData.coefficients[0 * 2 + 1].a );

    // [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor *= 1.25
    // This is a pure visual trick that provides a smooth falloff for greater perceived depth
    // of a surface. There is also a compensation factor that scales the intensity to account
    // for energy conservation. This factor needs to be revisted after vertical slice.
    //
    // this macro is defined in core.fxh. compensation factor set in core_<platform>.fxh
    SQUARE_FALLOFF_VMF(vmfIntensity_0);


    // indirect lighting
    float3 vmfDir_1       = VMFGetVector(vmfData, 1);
    float3 vmfColor_1     = vmfData.coefficients[1 * 2 + 1].rgb;
    float  vmfIntensity_1 = VMFEvaluateBandwidth( dot(vmfDir_1, normal), vmfData.coefficients[1 * 2 + 1].a );

    // [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor *= 1.25
    // this macro is defined in core.fxh. compensation factor set in core_<platform>.fxh
    SQUARE_FALLOFF_VMF(vmfIntensity_1);

    // direct back lighting (simple translucence)
    float3 vmfDiffuse_back_0 = (1-vmfIntensity_0);
    float ldotv_0            = saturate(dot(vmfDir_0, view));
    vmfDiffuse_back_0        = (ldotv_0 + vmfDiffuse_back_0) * translucence;

    // indirect back lighting
    float3 vmfDiffuse_back_1 = (1-vmfIntensity_1);
    float ldotv_1           = saturate(dot(vmfDir_1, view));
    vmfDiffuse_back_1       = (ldotv_1 + vmfDiffuse_back_1) * translucence;

    // finalize...
    float3 direct   = vmfColor_0 * (vmfIntensity_0 + vmfDiffuse_back_0) / pi;
    float3 indirect = vmfColor_1 * (vmfIntensity_1 + vmfDiffuse_back_1) / pi;
    float3 vmfDiffuse = direct + indirect;

    return vmfDiffuse;
}


float3 VMFSimpleLighting(
    const in s_vmf_sample_data vmfData,
    const in float3 normal)
{
    float3 vmfDiffuse =
        VMFCustomEvaluate(vmfData, float(1.0) ,  0) +
        VMFCustomEvaluate(vmfData, float(1.0) ,  1);

    return vmfDiffuse;
}


////////////////////////////////////////////////////////////////////////////////
// Returns the Phong specular evaluation of the VMF
float3 VMFSpecularPhong(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 viewDir,
    const in float specularMask,
    const in float specularPower)
{
    float3 reflectedView = reflect(viewDir, normal);		// mboulton -- I think this is wrong -- should be reflect(+viewDir, normal)

    float2 VdotR = float2(
        saturate(dot(reflectedView, VMFGetVector(vmfData, 0))),
        saturate(dot(reflectedView, VMFGetVector(vmfData, 1))));

	// Do some work in logarithmic space (specular power along with a divide by pi)
	float2 phongPower = log2(VdotR);
	phongPower = phongPower * specularPower - log2(pi);
	phongPower = exp2(phongPower);

	// The result of the exponential cannot be negative, so call the 'no clamp' evaluation to save time
    float3 vmfSpecular =
        VMFSpecularCustomEvaluateNoClamp(vmfData, phongPower.x, 0) +
        VMFSpecularCustomEvaluateNoClamp(vmfData, phongPower.y, 1);

	return vmfSpecular * specularMask;		// divide by pi is baked into power
}

////////////////////////////////////////////////////////////////////////////////
// Returns the Blinn specular evaluation of the VMF
float3 VMFSpecularBlinn(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 viewDir,
    const in float specularMask,
    const in float specularPower)
{
    float3 H[2] = {
        normalize(VMFGetVector(vmfData, 0) - viewDir),
        normalize(VMFGetVector(vmfData, 1) - viewDir) };

	// Get the cosines of the half-angles
    float2 NdotH = float2(
        saturate(dot(H[0], normal)),
        saturate(dot(H[1], normal)));

	// Do some work in logarithmic space (specular power along with a divide by pi)
	float2 blinnPower = log2(NdotH);
	blinnPower = blinnPower * specularPower - log2(pi);
	blinnPower = exp2(blinnPower);

	// The result of the exponential cannot be negative, so call the 'no clamp' evaluation to save time
    float3 vmfSpecular =
        VMFSpecularCustomEvaluateNoClamp(vmfData, blinnPower.x, 0) +
        VMFSpecularCustomEvaluateNoClamp(vmfData, blinnPower.y, 1);

    return vmfSpecular * specularMask;		// divide by pi is baked into power
}



// Returns the Ward specular evaluation of the VMF

float2 SpecularWard2(
	float3 L1,
	float3 L2,
    float3 N,
	float3 V,
#if defined(ANISOTROPIC_WARD)
	float3 B,
	float3 T,
#endif
	float2 aniso_roughness)
{
     // Evaluate the specular exponent
    aniso_roughness += float2(1e-5f, 1e-5f );

	float3 H1		= (L1 - V);					// No need to normalize, since we can divide by equal proportions later
	float3 H2		= (L2 - V);

	float VdotN		= dot(V, N);
	float2 LdotN	= float2(dot(N, L1), dot(N, L2));
	float2 HdotN	= float2(dot(N, H1), dot(N, H2));

#if defined(ANISOTROPIC_WARD)

    float2 HdotT	= float2(dot(T, H1), dot(T, H2));
    float2 HdotB	= float2(dot(B, H1), dot(B, H2));

    float2 betaA	= HdotT / aniso_roughness.xx;
    float2 betaB	= HdotB / aniso_roughness.yy;
    float2 beta		= -((betaA * betaA + betaB * betaB) / (HdotN * HdotN));

    // Evaluate the specular denominator
	float2 s_den	= sqrt(abs(LdotN * VdotN)) * aniso_roughness.xx * aniso_roughness.yy;

#else

	// Evaluate the specular exponent
	float2 rho		= (float2(dot(H1, H1), dot(H2, H2)) - (HdotN * HdotN)) / (HdotN * HdotN);
	float2 beta		= -(rho) / (aniso_roughness.xx * aniso_roughness.xx);

	// Evaluate the specular denominator
	float2 s_den	= sqrt(abs(LdotN * VdotN)) * aniso_roughness.xx * aniso_roughness.xx;

#endif

#if defined(cgfx) || (DX_VERSION == 11)
	s_den		= 1.0 / max(s_den, 1e-5f);
#else
	s_den		= 1.0 / s_den;
#endif

	// Effectively a divide by 4 * pi
	beta -= log(4.0 * pi + pi);

	return exp(beta) * s_den * LdotN;
}


float3 VMFSpecularWard(
    const in s_common_shader_data common,
    const in float3 normal,
    const in float specularMask,
    const in float2 aniso_roughness)
{
	s_vmf_sample_data vmfData = common.lighting_data.vmf_data;

#if defined(ANISOTROPIC_WARD)
	// Calculate a tangent frame oriented along the normal
    float3 B = safe_normalize(cross(normal, common.tangent_frame[0]));
	float3 T = cross(B, normal);						// normalized because N and B are orthogonal unit vectors
#endif

	float2 wardPower = SpecularWard2(
		VMFGetVector(vmfData, 0),
		VMFGetVector(vmfData, 1),
		normal,
		common.view_dir_distance.xyz,
#if defined(ANISOTROPIC_WARD)
		B,
		T,
#endif
		aniso_roughness);

    float3 vmfSpecular =
        VMFSpecularCustomEvaluate(vmfData, wardPower.x, 0) +
        VMFSpecularCustomEvaluate(vmfData, wardPower.y, 1);

    return vmfSpecular * specularMask;		// divide by pi is baked into power
}


s_vmf_sample_data get_default_vmf_data(void)
{
    s_vmf_sample_data vmf_data;
    vmf_data.coefficients[0]= 0.0f;
    vmf_data.coefficients[1]= 0.0f;
    vmf_data.coefficients[2]= 0.0f;
    vmf_data.coefficients[3]= 0.0f;
    return vmf_data;
}

s_vmf_ao_sample_data get_default_vmf_ao_data(void)
{
	s_vmf_ao_sample_data vmf_data;
	vmf_data.coefficients= 0.0f;
	return vmf_data;
}


void sample_lightprobe_constants(
    out s_vmf_sample_data vmf_data)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

	vmf_data = get_default_vmf_data();

#else

	vmf_data.coefficients[0]= ps_model_vmf_lighting[0];
    vmf_data.coefficients[1]= ps_model_vmf_lighting[1];
    vmf_data.coefficients[2]= ps_model_vmf_lighting[2];
    vmf_data.coefficients[3]= ps_model_vmf_lighting[3];

#endif
}

void get_lightprobe_constants_from_ao(
	inout s_vmf_sample_data vmf_data,
	in s_vmf_ao_sample_data vmf_ao_data,
	out float visibilityTerm)
{
	// Analytic scalar
	vmf_data.coefficients[1].w = vmf_ao_data.coefficients.x + vmf_ao_data.coefficients.w * ps_model_vmf_lighting[1].w;
	
	// AO
	vmf_data.coefficients[3].w = vmf_ao_data.coefficients.z;
	
	// Intensity modulation
	visibilityTerm = vmf_ao_data.coefficients.y;
}

float3 sample_lightprobe_texture_intensity_only(in float2 lightmap_texcoord)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)
	return 1.0f;
#else

	float3 lightmap_texcoord_bottom= float3(lightmap_texcoord, 0.0f);

	float4 tex[3];
	
#ifdef xenon
	// DXT5
	
	asm{ tfetch3D tex[0].xyzw, lightmap_texcoord_bottom, ps_bsp_lightprobe_hdr_color, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D tex[1].xyzw, lightmap_texcoord_bottom, ps_bsp_lightprobe_hdr_color, OffsetZ= 1.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	
	// DXT5a
	asm{ tfetch2D tex[2].x___, lightmap_texcoord_bottom, ps_bsp_lightprobe_analytic, MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
	tex[0] = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord_bottom.xy, 0));
	tex[1] = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord_bottom.xy, 1));
	tex[2].x = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord_bottom.xy).x;
#endif	

	// HDR scalars - Log scale
	const float baseExponent = log(1.0f / 512.0f);
	float2 v = float2(exp(baseExponent * tex[0].w), exp(baseExponent * tex[1].w));
	float2 hdrScalar = v.xy * ps_bsp_lightmap_compress_constant_1.xy + ps_bsp_lightmap_compress_constant_1.zw;

	// Direct HDR color
	float3 directColor = hdrScalar.x * tex[0].rgb;

	// Indirect HDR color
	float3 indirectColor = hdrScalar.y * tex[1].rgb;

	// Analytic scalar
	float analyticScalar = tex[2].x;
	
	float3 analyticColor = 0.0f;
	if (ps_boolean_using_floating_sun)
	{
		analyticColor = analyticScalar * ps_floating_shadow_light_intensity.xyz;
	}
	
	return directColor + indirectColor + analyticColor;

#endif //xenon
}

void sample_lightprobe_texture(
    in float2 lightmap_texcoord,
    in float view_distance,
    in s_common_shader_data common,
    out s_vmf_sample_data vmf_data,
    uniform int lightingMode)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

	vmf_data= get_default_vmf_data();

#else

	float3 lightmap_texcoord_bottom= float3(lightmap_texcoord, 0.0f);

	float4 tex[6];
	
#ifdef xenon	
	// DXN [-1, 1]
	asm{ tfetch3D tex[0].xyxy, lightmap_texcoord_bottom, ps_bsp_lightprobe_dir_and_bandwidth, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D tex[1].xyxy, lightmap_texcoord_bottom, ps_bsp_lightprobe_dir_and_bandwidth, OffsetZ= 1.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D tex[2].xyxy, lightmap_texcoord_bottom, ps_bsp_lightprobe_dir_and_bandwidth, OffsetZ= 2.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	
	// DXT5
	asm{ tfetch3D tex[3].xyzw, lightmap_texcoord_bottom, ps_bsp_lightprobe_hdr_color, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D tex[4].xyzw, lightmap_texcoord_bottom, ps_bsp_lightprobe_hdr_color, OffsetZ= 1.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
	tex[0] = ps_bsp_lightprobe_dir_and_bandwidth.t.Sample(ps_bsp_lightprobe_dir_and_bandwidth.s, float3(lightmap_texcoord_bottom.xy, 0)).xyxy;
	tex[1] = ps_bsp_lightprobe_dir_and_bandwidth.t.Sample(ps_bsp_lightprobe_dir_and_bandwidth.s, float3(lightmap_texcoord_bottom.xy, 1)).xyxy;
	tex[2] = ps_bsp_lightprobe_dir_and_bandwidth.t.Sample(ps_bsp_lightprobe_dir_and_bandwidth.s, float3(lightmap_texcoord_bottom.xy, 2)).xyxy;
	
	tex[3] = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord_bottom.xy, 0));
	tex[4] = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord_bottom.xy, 1));
#endif	
	
	// DXN
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW || lightingMode == LM_OBJECT)
	{
#ifdef xenon	
		asm{ tfetch2D tex[5].zw__, lightmap_texcoord_bottom, ps_bsp_lightprobe_analytic, MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
		tex[5].xy = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord_bottom.xy).xy;
#endif
	}
	// DXT5a
	else
	{
#ifdef xenon	
		asm{ tfetch2D tex[5].x___, lightmap_texcoord_bottom, ps_bsp_lightprobe_analytic, MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
		tex[5].x = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord_bottom.xy).x;
#endif
	}

	// HDR scalars - Log scale
	const float baseExponent = log(1.0f / 512.0f);
	float2 v = float2(exp(baseExponent * tex[3].w), exp(baseExponent * tex[4].w));
	float2 hdrScalar = v.xy * ps_bsp_lightmap_compress_constant_1.xy + ps_bsp_lightmap_compress_constant_1.zw;

	// Direct scalar SH
	vmf_data.coefficients[0].xyz = float3(tex[2].x, tex[0].xy);
	vmf_data.coefficients[0].w = sqrt(1.0f - dot(vmf_data.coefficients[0].xyz, vmf_data.coefficients[0].xyz));

	// Indirect scalar SH
	vmf_data.coefficients[2].xyz = float3(tex[2].y, tex[1].xy);
	vmf_data.coefficients[2].w = sqrt(1.0f - dot(vmf_data.coefficients[2].xyz, vmf_data.coefficients[2].xyz));
	
	// Staticly lit objects need linear SH to be rotated into object space
	if (lightingMode == LM_OBJECT)
	{
		vmf_data.coefficients[0].xyz = mul(vmf_data.coefficients[0].xyz, ps_light_rotation);
		vmf_data.coefficients[2].xyz = mul(vmf_data.coefficients[2].xyz, ps_light_rotation);
	}

	// Direct HDR color
	vmf_data.coefficients[1].xyz = hdrScalar.x * tex[3].rgb;

	// Indirect HDR color
	vmf_data.coefficients[3].xyz = hdrScalar.y * tex[4].rgb;

	// Analytic scalar
	vmf_data.coefficients[1].w = tex[5].x;

	// Ambient occlusion is baked into all static intensity; we need it for dynamic shadow
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW || lightingMode == LM_OBJECT)
	{
		vmf_data.coefficients[3].w = tex[5].y;
	}
	else
	{
		vmf_data.coefficients[3].w = 1.0f;
	}

	// REFINEMENT
	if (common.lighting_mode == LM_PER_PIXEL_HR ||
		common.lighting_mode == LM_PER_PIXEL_ANALYTIC_HR)
	{
		const float refinement_block_size = 5.0f;
		const float refinement_block_offset = 0.5f;
		const float max_refinement_distance = 8.0f;
		const float refinement_fade_start = 5.0f;
		const float overlay_width = floor(8060 / refinement_block_size);

		// Check for required refinement
		[branch]
		if (view_distance < max_refinement_distance)
		{
			// Refinement
			float overlay_micro;

#ifdef xenon			
			asm{ tfetch2D overlay_micro.w___, lightmap_texcoord, ps_bsp_lightprobe_hybrid_overlay_micro, MinFilter =point,MagFilter =point,MipFilter =point};
#else
			overlay_micro = sample2D(ps_bsp_lightprobe_hybrid_overlay_micro, lightmap_texcoord).w;
#endif

			[predicateBlock]
			if (overlay_micro.x > 0.0f)
			{
				float2 overlay_macro;
#ifdef xenon				
				asm{ tfetch2D overlay_macro.yx__, lightmap_texcoord, ps_bsp_lightprobe_hybrid_overlay_macro, MinFilter =point,MagFilter =point,MipFilter =point};
#else
				overlay_macro.xy = sample2D(ps_bsp_lightprobe_hybrid_overlay_macro, lightmap_texcoord).xy;
#endif

				overlay_micro = floor(overlay_micro * 255 - 0.5f) * refinement_block_size;
				overlay_macro = floor(overlay_macro * 65535 + 0.5f) * refinement_block_size;

				float2 overlay = overlay_macro;
				overlay.x += overlay_micro;
				
				// Residual across block
				// ps_bsp_lightmap_compress_constant_2.z == texture width
				float2 residual = frac(lightmap_texcoord * ps_bsp_lightmap_compress_constant_2.z);

				// Texel to fetch
				float2 unnorm_texel_address = overlay + residual * 4.0f;

				// Fetch!
				{
					float distance_fade = saturate((view_distance - refinement_fade_start) / (max_refinement_distance - refinement_fade_start));
					float intensity_factor;
#ifdef xenon					
					asm{ tfetch2D intensity_factor.x___, unnorm_texel_address.xy, ps_bsp_lightprobe_hybrid_refinement, UnnormalizedTextureCoords=true, MagFilter =linear,MinFilter =linear, OffsetX = refinement_block_offset, OffsetY = refinement_block_offset };
#else
					float refinement_width, refinement_height;
					ps_bsp_lightprobe_hybrid_refinement.t.GetDimensions(refinement_width, refinement_height);
					intensity_factor = ps_bsp_lightprobe_hybrid_refinement.t.SampleLevel(ps_bsp_lightprobe_hybrid_refinement.s, (unnorm_texel_address.xy + 0.5f) / float2(refinement_width, refinement_height), 0).x;
#endif					

					// Expand to our quantization range.
					intensity_factor *= 15.0f / 14.0f;
					
					vmf_data.coefficients[1].xyz *= intensity_factor * (1.0 - distance_fade) + distance_fade;
				}
			}
		}
	}

#endif //xenon
}

void sample_lightprobe_texture_forge(
    in float2 lightmap_texcoord,
    in float view_distance,
    inout s_common_shader_data common,
    in float3 geoNormal,
    out s_vmf_sample_data vmf_data)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

	vmf_data= get_default_vmf_data();
#else
	// get the lightprobe constants
	sample_lightprobe_constants(vmf_data);

	float3 lightmap_texcoord_bottom= float3(((lightmap_texcoord.x + LIGHT_PACKING_INDEX_HOR) / LIGHT_PACKING_SIZE), ((lightmap_texcoord.y + LIGHT_PACKING_INDEX_VER) / LIGHT_PACKING_SIZE), 0.0f);

	// $TODO - The following two textures each only use one component and thus can be combined

	float4 tex[2];
#ifdef xenon
	asm{ tfetch3D tex[0].xyxy, lightmap_texcoord_bottom, ps_bsp_lightprobe_dir_and_bandwidth, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D tex[1].xyzw, lightmap_texcoord_bottom, ps_bsp_lightprobe_hdr_color, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
	tex[0] = ps_bsp_lightprobe_dir_and_bandwidth.t.Sample(ps_bsp_lightprobe_dir_and_bandwidth.s, float3(lightmap_texcoord_bottom.xy, 0)).xyxy;
	tex[1] = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord_bottom.xy, 0));
#endif

	// Transform the hdr scalar back into the right range
	float hdrScalar;

	common.lighting_data.visibility = tex[1].a;

	// Analytic scalar
	vmf_data.coefficients[1].w = saturate(tex[0].x * 0.5f + 0.5f);		// texture format has bx2

	// we don't use ambient occlusion for forge-baked lightmaps
	vmf_data.coefficients[3].w = 1.0;

#endif //xenon
}

void sample_lightprobe_texture_simple_irradiance(
    in float2 lightmap_texcoord,
    in float view_distance,
    in s_common_shader_data common,
    out s_vmf_sample_data vmf_data,
    uniform int lightingMode)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

	vmf_data= get_default_vmf_data();

#else

#ifndef xenon
	vmf_data= get_default_vmf_data();
#endif

	float4 irradiance;
	float4 analyticAO;
	
#ifdef xenon
	// DXT5 irradiance	
	asm{ tfetch2D irradiance.xyzw, lightmap_texcoord, ps_bsp_lightprobe_hdr_color, MipFilter=point, MinFilter=linear, MagFilter=linear };
#else
	irradiance = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(lightmap_texcoord,0));
#endif
	
	// DXN AO and analytic light intensity
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE)
	{
#ifdef xenon	
		asm{ tfetch2D analyticAO.zw__, lightmap_texcoord, ps_bsp_lightprobe_analytic, MipFilter=point, MinFilter=linear, MagFilter=linear };
#else
		analyticAO.xy = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord).xy;
#endif
	}
	// DXT5a
	else
	{
#ifdef xenon	
		asm{ tfetch2D analyticAO.x___, lightmap_texcoord, ps_bsp_lightprobe_analytic, MipFilter=point, MinFilter=linear, MagFilter=linear };
#else
		analyticAO.x = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord).x;
#endif
	}

	const float baseExponent = log(1.0f / 512.0f);
	float hdrScalar = exp(baseExponent * irradiance.w) * ps_bsp_lightmap_compress_constant_1.x + ps_bsp_lightmap_compress_constant_1.z;
	vmf_data.coefficients[0].xyz = hdrScalar * irradiance.xyz;		// HDR irradiance stored here

	// Analytic scalar
	vmf_data.coefficients[1].w = analyticAO.x;

	// Ambient occlusion is baked into all static intensity; we need it for dynamic shadow
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE)
	{
		vmf_data.coefficients[3].w = analyticAO.y;
	}
	else
	{
		vmf_data.coefficients[3].w = 1.0f;
	}

#endif //xenon
}

void sample_lightprobe_texture_ao(
	in float2 lightmap_texcoord,
	in float view_distance,
	in s_common_shader_data common,
	out s_vmf_sample_data vmf_data,
	uniform int lightingMode)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)
	vmf_data= get_default_vmf_data();
#else

	// get the lightprobe constants
	sample_lightprobe_constants(vmf_data);
	
	float4 analyticAO;
	
#ifdef xenon	
	// DXN AO and analytic light intensity
	asm{ tfetch2D analyticAO.zw__, lightmap_texcoord, ps_bsp_lightprobe_analytic, MipFilter=point, MinFilter=linear, MagFilter=linear };
#else
	analyticAO.xy = sample2D(ps_bsp_lightprobe_analytic, lightmap_texcoord).xy;
#endif

	// Analytic scalar
	vmf_data.coefficients[1].w = analyticAO.x;
	
	// AO
	vmf_data.coefficients[3].w = analyticAO.y;

#endif //xenon
}

void sample_lightprobe_texture_565_ao_vs(
	in int vertexIndex,
	out s_vmf_ao_sample_data vmf_data)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

	vmf_data = get_default_vmf_ao_data();

#else
	// See faux_task_gpu_hybridlighting.cpp $Vertex AO
	float3 texData;

	// reconstruct coord from vs_mesh_lightmap_compress_constant.z
	{
		int3 unnormTexcoord = 0;
		int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;
		unnormTexcoord.x = offsetVertexIndex % 1024;
		unnormTexcoord.y = offsetVertexIndex / 1024;
#ifdef xenon		
		asm{ tfetch3D texData.xyz_, unnormTexcoord, vs_bsp_lightprobe_ao_data, OffsetZ = 0.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
#else
		texData.xyz = vs_bsp_lightprobe_ao_data.t.Load(int4(unnormTexcoord.xy,0,0)).xyz;
#endif
	}
	
	// Analytic, intensity mod, and AO
	texData.y *= 2.0f; // Expand intensity modulation
	vmf_data.coefficients.xyz = texData.xyz;
	
	// Scalar for optional analytic contribution from probe
	vmf_data.coefficients.w = vs_mesh_lightmap_compress_constant.w;	
#endif
}

void sample_lightprobe_texture_565_vs(
	in int vertexIndex,
	out s_vmf_sample_data vmf_data)
{
#if (!defined(xenon) && (DX_VERSION == 9)) || defined(DISABLE_VMF)

    vmf_data = get_default_vmf_data();

#else
	float3 rgb1, rgb2;

	// See faux_task_gpu_hybridlighting.cpp $Vertex SH
	float3 shData1, shData2, shData3;

	// reconstruct coord from vs_mesh_lightmap_compress_constant.z
	{
		int3 unnormTexcoord = 0;
		int offsetVertexIndex = vertexIndex + (int)vs_mesh_lightmap_compress_constant.z;
		unnormTexcoord.x = offsetVertexIndex % 1024;
		unnormTexcoord.y = offsetVertexIndex / 1024;
#ifdef xenon		
		asm{ tfetch3D rgb1.xyz_, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 0.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
		asm{ tfetch3D rgb2.xyz_, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 1.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
		asm{ tfetch3D shData1.xyz_, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 2.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
		asm{ tfetch3D shData2.xyz_, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 3.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
		asm{ tfetch3D shData3.xyz_, unnormTexcoord, vs_bsp_lightprobe_data, OffsetZ = 4.0, UseComputedLOD=false,UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point, UnnormalizedTextureCoords=true };
#else
		rgb1.xyz = vs_bsp_lightprobe_data.t.Load(int4(unnormTexcoord.xy,0,0)).xyz;
		rgb2.xyz = vs_bsp_lightprobe_data.t.Load(int4(unnormTexcoord.xy,1,0)).xyz;
		shData1.xyz = vs_bsp_lightprobe_data.t.Load(int4(unnormTexcoord.xy,2,0)).xyz;
		shData2.xyz = vs_bsp_lightprobe_data.t.Load(int4(unnormTexcoord.xy,3,0)).xyz;
		shData3.xyz = vs_bsp_lightprobe_data.t.Load(int4(unnormTexcoord.xy,4,0)).xyz;
#endif
	}

	float3 dirDirect   = float3(shData1.r, shData2.r, shData3.r) * 2.0f - 1.0f;
	float3 dirIndirect = float3(shData1.b, shData2.b, shData3.b) * 2.0f - 1.0f;

	vmf_data.coefficients[0].w = sqrt(max(0, 1.0f + dot(dirDirect,-dirDirect)));
	vmf_data.coefficients[2].w = sqrt(max(0, 1.0f + dot(dirIndirect,-dirIndirect)));

	vmf_data.coefficients[0].rgb = dirDirect;
	vmf_data.coefficients[2].rgb = dirIndirect;

	const float baseExponent = log(1.0f / 512.0f);
	float fIntensity = exp(baseExponent * shData3.g);

	vmf_data.coefficients[1].rgb = rgb1 * vs_bsp_lightmap_compress_constant.x * fIntensity;
	vmf_data.coefficients[3].rgb = rgb2 * vs_bsp_lightmap_compress_constant.y * fIntensity;

	vmf_data.coefficients[1].w = shData2.g;	// Sun
	vmf_data.coefficients[3].w = shData1.g; // AO	
#endif
}

static float floating_shadow_get_frustum_lerp_transition_value(float3 floatingShadowFrustumSpacePos)
{
	float3 distancesFromEdge = abs(floatingShadowFrustumSpacePos) - float3(ps_floating_shadow_light_intensity.w, ps_floating_shadow_light_direction.w, ps_floating_shadow_light_direction.w);
	float maxDistance = maxcomp(distancesFromEdge);

	// less than 0 means fully inside the frustum, 0-1 means within 1 world unit from the edge, and greater than 1 means past the edge
	// so we clamp to (0,1) so we can use it as a lerp
	return saturate(1.0 + maxDistance);
}

void apply_shadow_mask_to_vmf(inout s_common_shader_data common, bool useFloatingShadow, uniform int lightingMode)
{
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)

	float modifiedAnalyticScalar;
	if (useFloatingShadow)				// Only apply this if floating sun enabled
	{
		float analyticScalar = VMFGetAnalyticLightScalar(common.lighting_data.vmf_data);
		
		// Apply static sun shadow sharpening
		if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW)
		{
			analyticScalar = saturate(analyticScalar * ps_static_floating_shadow_sharpening.x - ps_static_floating_shadow_sharpening.y);
		}
		
		// Use sun sharpening value of 1.0 for forge objects.
		if (lightingMode == LM_PER_PIXEL_FORGE)
		{
			analyticScalar = saturate(analyticScalar * 2.0f - 0.5f);
		}

		// how much we are in the frustum (0 means all-in)
		float frustum_lerp_transition_value = floating_shadow_get_frustum_lerp_transition_value(common.shadowProjection);

		// we want to remember how much the sample is in the sun
		common.lighting_data.savedAnalyticScalar = analyticScalar;

		// modify the sun amount based upon clouds and the sun shadow map and push back into analytic scalar
		modifiedAnalyticScalar =  lerp(common.lighting_data.shadow_mask.r, analyticScalar, frustum_lerp_transition_value);

		if (lightingMode != LM_PROBE && lightingMode != LM_PROBE_AO && lightingMode != LM_OBJECT && lightingMode != LM_PER_PIXEL_FORGE)
		{
#if !defined(DISABLE_SUN_CLAMP)
			// If the vmf texture is marked as totally shadowed, then we clamp to zero
			if (VMFGetAnalyticLightScalar(common.lighting_data.vmf_data) == 0.0f)
			{
				modifiedAnalyticScalar = 0.0f;
			}
#endif
		}
	}
	// otherwise, we just want the character shadow to knock out analytic lights
	else
	{
		modifiedAnalyticScalar = VMFGetAnalyticLightScalar(common.lighting_data.vmf_data);
		common.lighting_data.savedAnalyticScalar = 0.0f;
	}
			
#ifndef MATERIAL_CONTROLS_SHADOW_MASK_READOUT
	modifiedAnalyticScalar *= common.lighting_data.shadow_mask.b;
#endif
	// Write back the modified analytic light intensity
	VMFSetAnalyticLightScalar(common.lighting_data.vmf_data, modifiedAnalyticScalar);

	// [mboulton 7/25/2011] Directly apply SSAO scalar
	// common.lighting_data.vmf_data.coefficients[1].xyz *= common.lighting_data.shadow_mask.a;
	// common.lighting_data.vmf_data.coefficients[3].xyz *= common.lighting_data.shadow_mask.a;
#endif //xenon
}


#endif  // !defined(__VMF_FXH)
