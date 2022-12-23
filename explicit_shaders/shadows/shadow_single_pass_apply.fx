#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "exposure.fxh"

// use this define when the albedo buffer is 7e3, which currently it is not
//#define USE_7E3

LOCAL_SAMPLER2D(shadow_sampler, 0);
LOCAL_SAMPLER2D(image_sampler, 1);


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
};

s_vertex_output_screen_tex default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	return output;
}


#if defined(xenon) && defined(USE_7E3)

float4 fetch7e3( sampler2D s, float2 vTexCoord )
{
	float4 vColor;
	
	//  This is done in assembly to emphasize POINT SAMPLING.
	//  If you do not point sample, you will be averaging floating data
	//  as an integer and errors will be introduced.  You do not have to do this
	//  if you set your sampler states correctly, but this is just a safety.
	//  You can choose to filter as integer but it will not be accurate.
	asm
	{
		tfetch2D vColor.bgra, vTexCoord.xy, s, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled		
	};
	
	// Now that we have the color, we just need to perform standard 7e3 conversion.	
	
	// Shift left 3 bits. This allows us to have the exponent and mantissa on opposite
	// sides of the decimal point for extraction.
	// We comment this out, because this is done instead in the state as Format.ExpAdjust = 3	
	// If we didn't do that in the sampler state, we would do it here.
	// vColor.rgb *= 8.0f;

	// Extract the exponent and mantissa that are now on opposite sides of the decimal point.
	float3 e = floor( vColor.rgb );
	float3 m = frac( vColor.rgb );
	
	// Perform the 7e3 conversion.  Note that this varies on the value of e for each channel:
	// if e != 0.0f then the correct conversion is (1+m)/8*pow(2,e).
	// else it is (1+m)/8*pow(2,e).  
	// Note that 2^0 = 1 so we can reduce this more.
	// Removing the /8 and putting it inside the pow() does not save instructions		
	vColor.rgb  = (e == 0.0f) ? 2*m/8 : (1+m)/8 * pow(2,e);    	

	return vColor;
}

#endif	// defined(xenon) && defined(USE_7E3)


float4 default_ps(const in SCREEN_POSITION_INPUT(vpos)) : SV_Target
{
#if !defined(xenon) && (DX_VERSION != 11)
 	return 1.0f;
#else	 // !defined(xenon)

	float4 result_shadow;
	float4 result_image;
#ifdef xenon	
	asm
	{
		tfetch2D result_shadow, vpos, shadow_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#else
	result_shadow = shadow_sampler.t.Load(int3(vpos.xy, 0));
#endif

#if defined(USE_7E3)
	result_image= fetch7e3(image_sampler, vpos);
#elif defined(xenon)
	asm
	{
		tfetch2D result_image, vpos, image_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#else
	result_image = image_sampler.t.Load(int3(vpos.xy, 0));
#endif	// defined(USE_7E3)

	// [adamgold 6/19/12] in sun, use the analytic knockout, in shade, use the direct knockout value
	// not all black on the shadow please
	float shadow = saturate(result_shadow.b * result_shadow.r + result_shadow.g * (1.0 - result_shadow.r) + 0.5);
	

	// reconstruct from RGBk and expose
	result_image.rgb = UnpackRGBk(result_image) * shadow * ps_view_exposure.rrr;

	return float4(result_image.rgb, 0);
#endif	// !defined(xenon)
}




BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


