#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "forge_lightmap_postprocess_registers.fxh"

#define forge_bx2_inv_1024(x)	(((x) * 511.0 / 1023.0) + 512.0 / 1023.0)

#define LIGHT_PACKING_INDEX_HOR ps_forge_lightmap_packing_constant.x
#define LIGHT_PACKING_SIZE ps_forge_lightmap_packing_constant.y
#define LIGHT_PACKING_INDEX_VER ps_forge_lightmap_packing_constant.z

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

/**
 * Take pixels in a 3x3 grid around the draw-to point and either median filter or box filter
 */
float4 blur(float blankTest, float4 blendedPixels[9], float4 sumTex, int numBlendedPixels)
{
	if (numBlendedPixels > 0)
	{
		// if it was blank, we want to do the median
		if (blankTest == 0.0)
		{
			float4 temp;
			
			for(int n = numBlendedPixels - 1; n; --n) 			
			{ 											
				for(int j = 0; j < n; ++j)
				{ 										
					temp = min(blendedPixels[j], blendedPixels[j+1]); 		
					blendedPixels[j+1] = max(blendedPixels[j], blendedPixels[j+1]);
					blendedPixels[j]   = temp; 					
				} 										
			}											
		
			return (blendedPixels[(numBlendedPixels - 1) * 0.5]);
		}
		// otherwise, box filter
		else
		{
			return (sumTex / numBlendedPixels);
		}
	}
	else
	{
		// don't touch island pixels
		return sumTex;
	}
}

/**
 * Apply indoor lighting and re-scale by magnitude (to improve compression)
 */
float4 post(float4 tex)
{	

	float maxValue = tex.r;
	if (tex.g > maxValue)
		maxValue = tex.g;
	if (tex.b > maxValue)
		maxValue = tex.b;
		
	tex.rgb /= maxValue;	
	
	// store the max value in the w component so that we can re-create the original color on readout
	tex.w = maxValue;
	
	return tex;
}

/**
 * VS for pasting standard textures to the render target
 */
s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

/**
 * PS to paste a texture to a render target
 */
void paste_regular_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
#if defined(xenon)
	float2 texcoord = input.texcoord.xy;
	asm{ 	tfetch2D	outColor, texcoord, ps_texture_sampler, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled };		
#elif DX_VERSION == 11
	outColor = sample2D(ps_texture_sampler, input.texcoord.xy);
#else
	outColor = float4(1.0, 1.0, 1.0, 0.0);		
#endif
}

/**
 * PS to paste a DXN texture to the render target, folded over on itself so that the left half is in the red channel and the right half is in the green channel
 */
void paste_folded_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
#if defined(xenon) || (DX_VERSION == 11)
	float2 texcoord2Left, texcoord2Right;
	texcoord2Left.x = input.texcoord.x / 2;
	texcoord2Right.x = input.texcoord.x / 2 + 0.5;
	texcoord2Left.y = texcoord2Right.y = input.texcoord.y; // not tiling in Y, just in X
	
	// get the left half of the texture and put it in the x component
#ifdef xenon	
	asm{ 	tfetch2D outColor.x___, texcoord2Left, ps_bsp_lightprobe_hdr_color, 
		MipFilter=point,MinFilter=point,MagFilter=point };
			
	// get the right half of the texture and put it in the z component (for the DXN texture we're fetching from, z and x are the same value anyway because it's stored as xyxy)
	asm{ 	tfetch2D outColor.__z_, texcoord2Right, ps_bsp_lightprobe_hdr_color, 
		MipFilter=point,MinFilter=point,MagFilter=point };
#else
	outColor.x = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(texcoord2Left, 0)).x;
	outColor.z = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(texcoord2Right, 0)).x;
#endif
	
	outColor = float4(outColor.x, 1.0, outColor.z, 1.0);
#else
	outColor = float4(1.0, 1.0, 1.0, 0.0);		
#endif
}

/**
 * PS for post-processing the forge-object color texture
 */
void default_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
#if defined(xenon) || (DX_VERSION == 11)
	float2 texcoord2 = float2(((input.texcoord.x + LIGHT_PACKING_INDEX_HOR) / LIGHT_PACKING_SIZE), ((input.texcoord.y + LIGHT_PACKING_INDEX_VER) / LIGHT_PACKING_SIZE));
	float4 sumTex = float4(0.0, 0.0, 0.0, 0.0);
	int blendedPixels = 0;
	
	// fetch all 9 pixels
	float4 rawData[9];
		
	float4 original = rawData[0] =	Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0,  0);
	
	// if the original has an alpha of 1, it means it was drawn-to, so it should be added to the sum
	if (original.a == 1.0)
	{
		sumTex += original;
		blendedPixels++;
	}
	
	// if the original wasn't lit, then we can forgo the threshold test
	float blurThreshold = (original.a == 0.0 || original.rgb == 0.0) ? 1.0 : (ps_constant_blur_threshold);
	
	rawData[1] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1, -1);
	rawData[2] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0, -1);
	rawData[3] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  1, -1);
	rawData[4] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1,  0);
	rawData[5] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  1,  0);
	rawData[6] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1,  1);
	rawData[7] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0,  1);
	rawData[8] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  1,  1);
	
	// we only want to blend in lit pixels around it
	for(int i = 1; i < 9; ++i)
	{
		float4 color = rawData[i];
		
		if (color.a > 0.0          
			&& (original.a == 0.0 || all(abs((original.rgb - color.rgb) / (0.5 * (original.rgb + color.rgb))) < blurThreshold)))
		{
			sumTex += color;
			rawData[blendedPixels] = color; // slide all of the "lit" pixels into the top part of the rawData array, overwriting the garbage "unlit" pixels if need be
			blendedPixels++;
		}
	}
	
	outColor = blur(original.a, rawData, sumTex, blendedPixels);	
	outColor = post(outColor);			
#else
	outColor = sample2D(ps_texture_sampler, input.texcoord);
#endif
}

/**
 * PS for post-processing the forge-object sun texture
 */
void sun_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
#if defined(xenon) || (DX_VERSION == 11)
	float4 original;
	float2 texcoord2 = input.texcoord.xy;
	
	// fetch all 9 pixels
	float4 rawData[9];			  
	for(int dX = -1; dX <= 1; ++dX)
	{
		for(int dY = -1; dY <= 1; ++dY) 
		{	
			rawData[(dX + 1) * 3 + (dY + 1)] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, dX, dY);
		}
	}
	
	outColor = original = rawData[4];

	// if the original wasn't lit, then we can forgo the threshold test
	float blurThreshold = (original.r == 0.0) ? 1.0 : (ps_constant_blur_threshold);
	
	// can't overwrite the rawData array like we did with the default_ps beacuse we need to do it twice now, and we can't overwrite the original raw values as we go
	// so, we have to create this new array to hold the sorted, hand-picked list of relevant pixels
	float4 blendedPixels[9] = { float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0) };
	int numBlendedPixels = 0;
	float4 sumTex = float4(0.0, 0.0, 0.0, 0.0);
	
	/////////////////////////////////////////////////////////////////////////
	// RED CHANNEL (left half of original)
	/////////////////////////////////////////////////////////////////////////	
	// we only want to blend in lit pixels around it
	[unroll]
	for(int i = 0; i < 9; ++i)
	{
		float4 color = rawData[i];
       
		if (color.r > 0.0          
			&& (original.r == 0.0 || abs((original.r - color.r) / (0.5 * (original.r + color.r))) < blurThreshold))
		{
			sumTex += color;
			blendedPixels[numBlendedPixels++] = color;
		}
	}
	
	outColor.r = blur(original.r, blendedPixels, sumTex, numBlendedPixels).r;
	
	/////////////////////////////////////////////////////////////////////////
	// BLUE CHANNEL (right half of original)
	/////////////////////////////////////////////////////////////////////////
	numBlendedPixels = 0;
	sumTex = float4(0.0, 0.0, 0.0, 0.0);
	
	// we only want to blend in lit pixels around it
	[unroll]
	for(int i = 0; i < 9; ++i)
	{
		float4 color = rawData[i];
       
		if (color.b > 0.0          
			&& (original.b == 0.0 || abs((original.b - color.b) / (0.5 * (original.b + color.b))) < blurThreshold))
		{
			sumTex += color;
			blendedPixels[numBlendedPixels++].rgba = color.baba; // put the blue in the red channel too so that the bubble-sort works properly (it sorts by first index)
		}
	}
	
	outColor.b = blur(original.b, blendedPixels, sumTex, numBlendedPixels).b;
			
#else
	outColor = sample2D(ps_texture_sampler, input.texcoord);
#endif

}

/**
 * PS for post-processing the original sun channel now that new shadows have been burnt in
 */ 
float4 blur_sun_structure_ps_helper(const in s_screen_vertex_output input, bool shouldBlurGlobally)
{
	float4 outColor;
	
#if defined(xenon) || (DX_VERSION == 11)
	float2 texcoord2 = input.texcoord.xy;
	float2 texcoord2Left = input.texcoord.xy;
	float2 texcoord2Right = input.texcoord.xy;
	texcoord2Left.x = input.texcoord.x * 0.5;
	texcoord2Right.x = input.texcoord.x * 0.5 + 0.5;

	float4 borderSamples[8];
	float4 originalTexel = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0,  0);
	
	// compass directions
	borderSamples[0] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1,  0);
	borderSamples[1] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0, -1);
	borderSamples[2] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2,  0, +1);
	borderSamples[3] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, +1,  0);
	
	// diagonals
	borderSamples[4] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1, +1);
	borderSamples[5] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, -1, -1);
	borderSamples[6] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, +1, -1);
	borderSamples[7] = Sample2DOffsetPoint(ps_texture_sampler, texcoord2, +1, +1);
	
	// get AO values from the original so that we can paste them back in
	float4 leftAO, rightAO;	
#ifdef xenon	
	asm{ 	tfetch3D leftAO.___w, texcoord2Left, ps_bsp_lightprobe_hdr_color, 
		OffsetZ= 3.0, UseComputedLOD=false, UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point };
	asm{ 	tfetch3D rightAO.___w, texcoord2Right, ps_bsp_lightprobe_hdr_color, 
		OffsetZ= 3.0, UseComputedLOD=false, UseRegisterGradients=false, MinFilter=point, MagFilter=point, VolMinFilter=point, VolMagFilter=point };
#else
	leftAO.w = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(texcoord2Left, 3)).y;
	rightAO.w = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, float3(texcoord2Right, 3)).y;
#endif		
		
	/////////////////////////////////////////////////////////////////////////
	// RED CHANNEL (left half of original)
	/////////////////////////////////////////////////////////////////////////
	bool bordersDarkDrawnTexel = false;
	bool bordersBrightDrawnTexel = false;
	
	float4 sum;
	float weightSum;
	
	// start by weighting the original texel by 9 (if it was drawn to)
	if (originalTexel.g == 0.0)
	{
		sum = 9 * originalTexel;
		weightSum = 9;
	}
	else
	{
		sum = float4(0.0, 0.0, 0.0, 0.0);
		weightSum = 0;
	}
	
	for (int i = 0; i < 8; ++i)
	{
		// baby version of "gaussian" blur (weight = 3 if touching, = 1 on diagonals)
		float weight = (i <= 3 ? 3 : 1);
		
		// only add blend it into the blurred result if it was actually modified (this prevents bright edges  of charts from getting in and appearing as "seams")
		if (borderSamples[i].g == 0.0)
		{
			sum += weight * borderSamples[i];
			weightSum += weight;
			
			if (borderSamples[i].r < 0.5)
				bordersDarkDrawnTexel = true;
			else
				bordersBrightDrawnTexel = true;
		}
	}
	
	// if this is a pixel we've messed with  (or it's one which borders a new shadowed patch -- this allows us to smear shadow over the remaining "seams")
	if (shouldBlurGlobally || originalTexel.g == 0.0 || (bordersDarkDrawnTexel && !bordersBrightDrawnTexel))
	{
		// box filter!
		// and be sure to clamp 1 / 255 so that no value is pure zero, because it matters for the floating shadow when it's getting read out
		originalTexel.r = max(sum / weightSum, 1.0 / 255.0).r;	
	}
	
	/////////////////////////////////////////////////////////////////////////
	// BLUE CHANNEL (right half of original)
	/////////////////////////////////////////////////////////////////////////
	bordersDarkDrawnTexel = false;
	bordersBrightDrawnTexel = false;
	
	// start by weighting the original texel by 9 (if it was drawn to)
	if (originalTexel.a == 0.0)
	{
		sum = 9 * originalTexel;
		weightSum = 9;
	}
	else
	{
		sum = float4(0.0, 0.0, 0.0, 0.0);
		weightSum = 0;
	}
	
	for (int i = 0; i < 8; ++i)
	{
		// baby version of "gaussian" blur (9 in middle, 3 touching, 1 on diagonals)
		float weight = (i <= 3 ? 3 : 1);
		// only add blend it into the blurred result if it was actually modified (prevent bright edges  of charts from getting in and appearing as "seams")
		if (borderSamples[i].a == 0.0)
		{
			sum += weight * borderSamples[i];
			weightSum += weight;
			
			if (borderSamples[i].b < 0.5)
				bordersDarkDrawnTexel = true;
			else
				bordersBrightDrawnTexel = true;
		}
	}
	
	// if this is a pixel we've messed with ( (or it's one which borders a new shadowed patch -- this allows us to smear shadow over the "seams")
	if (shouldBlurGlobally || originalTexel.a == 0.0 || (bordersDarkDrawnTexel && !bordersBrightDrawnTexel))
	{
		// box filter!
		// and be sure to clamp 1 / 255 so that no value is pure zero because that matters for the floating shadow when it's getting read out
		originalTexel.b = max(sum / weightSum, 1.0 / 255.0).b;	
	}	
	
	outColor = float4(originalTexel.r, leftAO.w, originalTexel.b, rightAO.a);			
#else
	outColor = sample2D(ps_texture_sampler, input.texcoord);
#endif

	return outColor;
}

void blur_sun_structure_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
	outColor = blur_sun_structure_ps_helper(input, false);
}

void blur_sun_structure_global_blur_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
	outColor = blur_sun_structure_ps_helper(input, true);
}

/**
 * Techniques
 */
BEGIN_TECHNIQUE // post-process forge object color texture
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE // post-process forge object sun texture
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(sun_ps());
	}
}

BEGIN_TECHNIQUE // pasting a regular texture to a render target
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(paste_regular_ps());
	}
}

BEGIN_TECHNIQUE // pasting a folded texture to a render target
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(paste_folded_ps());
	}
}

BEGIN_TECHNIQUE // blur sun structure
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(blur_sun_structure_ps());
	}
}

BEGIN_TECHNIQUE // blur sun structure (blur globally for when we're recreating the sun texture from scratch)
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(blur_sun_structure_global_blur_ps());
	}
}