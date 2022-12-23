#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "lighting/forge_block_compress_registers.fxh"

LOCAL_SAMPLER2D(ps_surface_sampler,	0);

#if DX_VERSION == 9
void LoadTexelsRGBA(in float2 texCoord, out float4 RGBA[16])
{
#if defined(xenon)
    float4 RGBARaw00, RGBARaw01, RGBARaw02, RGBARaw03;
    float4 RGBARaw10, RGBARaw11, RGBARaw12, RGBARaw13;
    float4 RGBARaw20, RGBARaw21, RGBARaw22, RGBARaw23;
    float4 RGBARaw30, RGBARaw31, RGBARaw32, RGBARaw33;
	
    asm
    {  
        tfetch2D RGBARaw00, texCoord, ps_surface_sampler, OffsetX = -1.5f, OffsetY = -1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw10, texCoord, ps_surface_sampler, OffsetX = -0.5f, OffsetY = -1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw20, texCoord, ps_surface_sampler, OffsetX = +0.5f, OffsetY = -1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw30, texCoord, ps_surface_sampler, OffsetX = +1.5f, OffsetY = -1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw01, texCoord, ps_surface_sampler, OffsetX = -1.5f, OffsetY = -0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw11, texCoord, ps_surface_sampler, OffsetX = -0.5f, OffsetY = -0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw21, texCoord, ps_surface_sampler, OffsetX = +0.5f, OffsetY = -0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw31, texCoord, ps_surface_sampler, OffsetX = +1.5f, OffsetY = -0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw02, texCoord, ps_surface_sampler, OffsetX = -1.5f, OffsetY = +0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw12, texCoord, ps_surface_sampler, OffsetX = -0.5f, OffsetY = +0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw22, texCoord, ps_surface_sampler, OffsetX = +0.5f, OffsetY = +0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw32, texCoord, ps_surface_sampler, OffsetX = +1.5f, OffsetY = +0.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw03, texCoord, ps_surface_sampler, OffsetX = -1.5f, OffsetY = +1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw13, texCoord, ps_surface_sampler, OffsetX = -0.5f, OffsetY = +1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw23, texCoord, ps_surface_sampler, OffsetX = +0.5f, OffsetY = +1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
        tfetch2D RGBARaw33, texCoord, ps_surface_sampler, OffsetX = +1.5f, OffsetY = +1.5f, \
            MinFilter = point, MagFilter = point, MipFilter = point
    };

	
    RGBA[ 0] = RGBARaw00;
    RGBA[ 1] = RGBARaw10;
    RGBA[ 2] = RGBARaw20;
    RGBA[ 3] = RGBARaw30;
    RGBA[ 4] = RGBARaw01;
    RGBA[ 5] = RGBARaw11;
    RGBA[ 6] = RGBARaw21;
    RGBA[ 7] = RGBARaw31;
    RGBA[ 8] = RGBARaw02;
    RGBA[ 9] = RGBARaw12;
    RGBA[10] = RGBARaw22;
    RGBA[11] = RGBARaw32;
    RGBA[12] = RGBARaw03;
    RGBA[13] = RGBARaw13;
    RGBA[14] = RGBARaw23;
    RGBA[15] = RGBARaw33;	
#else
	for (int i = 0; i < 16; ++i)
	{
		RGBA[i] = float4(1.0, 1.0, 1.0, 1.0);
	}
#endif
}
#elif DX_VERSION == 11
void LoadTexelsRGBA(in uint2 block_coord, out float4 RGBA[16])
{
	uint2 coord = uint2(block_coord.x * 4, block_coord.y * 4);

	[unroll]
	for (int x = 0; x < 4; x++)
	{
		[unroll]
		for (int y = 0; y < 4; y++)
		{
			RGBA[(y * 4) + x] = ps_surface_sampler.t.Load(uint3(coord + uint2(x,y), 0));
		}
	}
}
#endif

#if DX_VERSION == 9
#define TFETCH_UV(dest, source, offsetX, offsetY) tfetch2D dest, texCoord, source, OffsetX = offsetX, OffsetY = offsetY, \
            MinFilter = point, MagFilter = point, MipFilter = point

void LoadTexelsUVFirstTile(in float2 texCoord, out float2 UV[16])
{
#if defined(xenon)
    float4 UVUVRaw00, UVUVRaw01, UVUVRaw02, UVUVRaw03;
    float4 UVUVRaw10, UVUVRaw11, UVUVRaw12, UVUVRaw13;
    float4 UVUVRaw20, UVUVRaw21, UVUVRaw22, UVUVRaw23;
    float4 UVUVRaw30, UVUVRaw31, UVUVRaw32, UVUVRaw33;
	
    asm
    {
	TFETCH_UV(UVUVRaw00.xy__, ps_surface_sampler, -1.5f, -1.5f)
	TFETCH_UV(UVUVRaw10.xy__, ps_surface_sampler, -0.5f, -1.5f)
	TFETCH_UV(UVUVRaw20.xy__, ps_surface_sampler, +0.5f, -1.5f)
	TFETCH_UV(UVUVRaw30.xy__, ps_surface_sampler, +1.5f, -1.5f)
	TFETCH_UV(UVUVRaw01.xy__, ps_surface_sampler, -1.5f, -0.5f)
	TFETCH_UV(UVUVRaw11.xy__, ps_surface_sampler, -0.5f, -0.5f)
	TFETCH_UV(UVUVRaw21.xy__, ps_surface_sampler, +0.5f, -0.5f)
	TFETCH_UV(UVUVRaw31.xy__, ps_surface_sampler, +1.5f, -0.5f)
	TFETCH_UV(UVUVRaw02.xy__, ps_surface_sampler, -1.5f, +0.5f)
	TFETCH_UV(UVUVRaw12.xy__, ps_surface_sampler, -0.5f, +0.5f)
	TFETCH_UV(UVUVRaw22.xy__, ps_surface_sampler, +0.5f, +0.5f)
	TFETCH_UV(UVUVRaw32.xy__, ps_surface_sampler, +1.5f, +0.5f)
	TFETCH_UV(UVUVRaw03.xy__, ps_surface_sampler, -1.5f, +1.5f)
	TFETCH_UV(UVUVRaw13.xy__, ps_surface_sampler, -0.5f, +1.5f)
	TFETCH_UV(UVUVRaw23.xy__, ps_surface_sampler, +0.5f, +1.5f)
	TFETCH_UV(UVUVRaw33.xy__, ps_surface_sampler, +1.5f, +1.5f)
    };
    
    UV[ 0] = UVUVRaw00.xy;
    UV[ 1] = UVUVRaw10.xy;
    UV[ 2] = UVUVRaw20.xy;
    UV[ 3] = UVUVRaw30.xy;
    UV[ 4] = UVUVRaw01.xy;
    UV[ 5] = UVUVRaw11.xy;
    UV[ 6] = UVUVRaw21.xy;
    UV[ 7] = UVUVRaw31.xy;
    UV[ 8] = UVUVRaw02.xy;
    UV[ 9] = UVUVRaw12.xy;
    UV[10] = UVUVRaw22.xy;
    UV[11] = UVUVRaw32.xy;
    UV[12] = UVUVRaw03.xy;
    UV[13] = UVUVRaw13.xy;
    UV[14] = UVUVRaw23.xy;
    UV[15] = UVUVRaw33.xy;  
#else
	for (int i = 0; i < 16; ++i)
	{
		UV[i] = float2(1.0, 1.0);
	}
#endif
}
#elif DX_VERSION == 11
void LoadTexelsUVFirstTile(in uint2 block_coord, out float2 UV[16])
{
	uint2 coord = uint2(block_coord.x * 4, block_coord.y * 4);

	[unroll]
	for (int x = 0; x < 4; x++)
	{
		[unroll]
		for (int y = 0; y < 4; y++)
		{
			UV[(y * 4) + x] = ps_surface_sampler.t.Load(uint3(coord + uint2(x,y), 0)).xy;
		}
	}
}
#endif

#if DX_VERSION == 9
void LoadTexelsUVSecondTile(in float2 texCoord, out float2 UV[16])
{
#if defined(xenon)
    float4 UVUVRaw00, UVUVRaw01, UVUVRaw02, UVUVRaw03;
    float4 UVUVRaw10, UVUVRaw11, UVUVRaw12, UVUVRaw13;
    float4 UVUVRaw20, UVUVRaw21, UVUVRaw22, UVUVRaw23;
    float4 UVUVRaw30, UVUVRaw31, UVUVRaw32, UVUVRaw33;
	
    asm
    {
	TFETCH_UV(UVUVRaw00.__zw, ps_surface_sampler, -1.5f, -1.5f)
	TFETCH_UV(UVUVRaw10.__zw, ps_surface_sampler, -0.5f, -1.5f)
	TFETCH_UV(UVUVRaw20.__zw, ps_surface_sampler, +0.5f, -1.5f)
	TFETCH_UV(UVUVRaw30.__zw, ps_surface_sampler, +1.5f, -1.5f)
	TFETCH_UV(UVUVRaw01.__zw, ps_surface_sampler, -1.5f, -0.5f)
	TFETCH_UV(UVUVRaw11.__zw, ps_surface_sampler, -0.5f, -0.5f)
	TFETCH_UV(UVUVRaw21.__zw, ps_surface_sampler, +0.5f, -0.5f)
	TFETCH_UV(UVUVRaw31.__zw, ps_surface_sampler, +1.5f, -0.5f)
	TFETCH_UV(UVUVRaw02.__zw, ps_surface_sampler, -1.5f, +0.5f)
	TFETCH_UV(UVUVRaw12.__zw, ps_surface_sampler, -0.5f, +0.5f)
	TFETCH_UV(UVUVRaw22.__zw, ps_surface_sampler, +0.5f, +0.5f)
	TFETCH_UV(UVUVRaw32.__zw, ps_surface_sampler, +1.5f, +0.5f)
	TFETCH_UV(UVUVRaw03.__zw, ps_surface_sampler, -1.5f, +1.5f)
	TFETCH_UV(UVUVRaw13.__zw, ps_surface_sampler, -0.5f, +1.5f)
	TFETCH_UV(UVUVRaw23.__zw, ps_surface_sampler, +0.5f, +1.5f)
	TFETCH_UV(UVUVRaw33.__zw, ps_surface_sampler, +1.5f, +1.5f)
    };
    
    UV[ 0] = UVUVRaw00.zw;
    UV[ 1] = UVUVRaw10.zw;
    UV[ 2] = UVUVRaw20.zw;
    UV[ 3] = UVUVRaw30.zw;
    UV[ 4] = UVUVRaw01.zw;
    UV[ 5] = UVUVRaw11.zw;
    UV[ 6] = UVUVRaw21.zw;
    UV[ 7] = UVUVRaw31.zw;
    UV[ 8] = UVUVRaw02.zw;
    UV[ 9] = UVUVRaw12.zw;
    UV[10] = UVUVRaw22.zw;
    UV[11] = UVUVRaw32.zw;
    UV[12] = UVUVRaw03.zw;
    UV[13] = UVUVRaw13.zw;
    UV[14] = UVUVRaw23.zw;
    UV[15] = UVUVRaw33.zw;  
#else
	for (int i = 0; i < 16; ++i)
	{
		UV[i] = float2(1.0, 1.0);
	}
#endif
}
#elif DX_VERSION == 11
void LoadTexelsUVSecondTile(in uint2 block_coord, out float2 UV[16])
{
	uint2 coord = uint2(block_coord.x * 4, block_coord.y * 4);

	[unroll]
	for (int x = 0; x < 4; x++)
	{
		[unroll]
		for (int y = 0; y < 4; y++)
		{
			UV[(y * 4) + x] = ps_surface_sampler.t.Load(uint3(coord + uint2(x,y), 0)).zw;
		}
	}
}
#endif

void FindMinMaxRGBA(float4 RGBA[16], out float4 minRGBA, out float4 maxRGBA)
{
    // Find the axis-aligned bounding box in color space.
    minRGBA = RGBA[0];
    maxRGBA = RGBA[0];
    for(int i = 0; i < 16; ++i)
    {
        minRGBA = min(minRGBA, RGBA[i]);
        maxRGBA = max(maxRGBA, RGBA[i]);
    }
}

void FindMinMaxUV(float2 UV[16], out float2 minUV, out float2 maxUV)
{
    // Find the axis-aligned bounding box in UV space.
    // This formulation gives best vector min/max op usage.
    float2 minUV0 = min(min(UV[ 0], UV[ 4]), min(UV[ 8], UV[12]));
    float2 minUV1 = min(min(UV[ 1], UV[ 5]), min(UV[ 9], UV[13]));
    float2 minUV2 = min(min(UV[ 2], UV[ 6]), min(UV[10], UV[14]));
    float2 minUV3 = min(min(UV[ 3], UV[ 7]), min(UV[11], UV[15]));
    
    minUV = min(min(minUV0, minUV1), min(minUV2, minUV3));
    
    float2 maxUV0 = max(max(UV[ 0], UV[ 4]), max(UV[ 8], UV[12]));
    float2 maxUV1 = max(max(UV[ 1], UV[ 5]), max(UV[ 9], UV[13]));
    float2 maxUV2 = max(max(UV[ 2], UV[ 6]), max(UV[10], UV[14]));
    float2 maxUV3 = max(max(UV[ 3], UV[ 7]), max(UV[11], UV[15]));
    
    maxUV = max(max(maxUV0, maxUV1), max(maxUV2, maxUV3));
}


#if DX_VERSION == 9
float4 EncodeDXT5AInternal(float alpha[16], float min, float max)
#elif DX_VERSION == 11
uint2 EncodeDXT5AInternal(float alpha[16], float min, float max, bool is_signed = false)
#endif
{    
    // For each input color, find the closest representable step along the line joining the anchors.

#if defined(xenon) || (DX_VERSION == 11)
    float stepInc = 7.0f / (max - min);
#else
	float stepInc = 7.0f;
#endif

    float paletteIndices[16];
	
    [unroll]
    for(int i = 0; i < 16; ++i)
    {
        paletteIndices[i] = round((max - alpha[i]) * stepInc);
    }

    // Remap palette indices according to DXT5A convention
    // [8 vector ops]
    paletteIndices[ 0] = (paletteIndices[ 0] == 0.0f) ? 0.0f : (paletteIndices[ 0] == 7.0f) ? 1.0f : (paletteIndices[ 0] + 1);
    paletteIndices[ 1] = (paletteIndices[ 1] == 0.0f) ? 0.0f : (paletteIndices[ 1] == 7.0f) ? 1.0f : (paletteIndices[ 1] + 1);
    paletteIndices[ 2] = (paletteIndices[ 2] == 0.0f) ? 0.0f : (paletteIndices[ 2] == 7.0f) ? 1.0f : (paletteIndices[ 2] + 1);
    paletteIndices[ 3] = (paletteIndices[ 3] == 0.0f) ? 0.0f : (paletteIndices[ 3] == 7.0f) ? 1.0f : (paletteIndices[ 3] + 1);
    paletteIndices[ 4] = (paletteIndices[ 4] == 0.0f) ? 0.0f : (paletteIndices[ 4] == 7.0f) ? 1.0f : (paletteIndices[ 4] + 1);
    paletteIndices[ 5] = (paletteIndices[ 5] == 0.0f) ? 0.0f : (paletteIndices[ 5] == 7.0f) ? 1.0f : (paletteIndices[ 5] + 1);
    paletteIndices[ 6] = (paletteIndices[ 6] == 0.0f) ? 0.0f : (paletteIndices[ 6] == 7.0f) ? 1.0f : (paletteIndices[ 6] + 1);
    paletteIndices[ 7] = (paletteIndices[ 7] == 0.0f) ? 0.0f : (paletteIndices[ 7] == 7.0f) ? 1.0f : (paletteIndices[ 7] + 1);
    paletteIndices[ 8] = (paletteIndices[ 8] == 0.0f) ? 0.0f : (paletteIndices[ 8] == 7.0f) ? 1.0f : (paletteIndices[ 8] + 1);
    paletteIndices[ 9] = (paletteIndices[ 9] == 0.0f) ? 0.0f : (paletteIndices[ 9] == 7.0f) ? 1.0f : (paletteIndices[ 9] + 1);
    paletteIndices[10] = (paletteIndices[10] == 0.0f) ? 0.0f : (paletteIndices[10] == 7.0f) ? 1.0f : (paletteIndices[10] + 1);
    paletteIndices[11] = (paletteIndices[11] == 0.0f) ? 0.0f : (paletteIndices[11] == 7.0f) ? 1.0f : (paletteIndices[11] + 1);
    paletteIndices[12] = (paletteIndices[12] == 0.0f) ? 0.0f : (paletteIndices[12] == 7.0f) ? 1.0f : (paletteIndices[12] + 1);
    paletteIndices[13] = (paletteIndices[13] == 0.0f) ? 0.0f : (paletteIndices[13] == 7.0f) ? 1.0f : (paletteIndices[13] + 1);
    paletteIndices[14] = (paletteIndices[14] == 0.0f) ? 0.0f : (paletteIndices[14] == 7.0f) ? 1.0f : (paletteIndices[14] + 1);
    paletteIndices[15] = (paletteIndices[15] == 0.0f) ? 0.0f : (paletteIndices[15] == 7.0f) ? 1.0f : (paletteIndices[15] + 1);
    
#if DX_VERSION == 9	
    // Pack 32 2-bit palette indices into 2 16-bit unsigned integers
    // First put 6 3-bit indices into each field (overshooting)
    float packedIndices[3];
    packedIndices[0] =  paletteIndices[ 0] + 
                8.0f * (paletteIndices[ 1] + 
                8.0f * (paletteIndices[ 2] + 
                8.0f * (paletteIndices[ 3] + 
                8.0f * (paletteIndices[ 4] + 
                8.0f * (paletteIndices[ 5]))))); 
    packedIndices[1] =  paletteIndices[ 5] + 
                8.0f * (paletteIndices[ 6] + 
                8.0f * (paletteIndices[ 7] + 
                8.0f * (paletteIndices[ 8] + 
                8.0f * (paletteIndices[ 9] + 
                8.0f * (paletteIndices[10]))))); 
    packedIndices[2] =  paletteIndices[10] + 
                8.0f * (paletteIndices[11] + 
                8.0f * (paletteIndices[12] + 
                8.0f * (paletteIndices[13] + 
                8.0f * (paletteIndices[14] + 
                8.0f * (paletteIndices[15]))))); 
            
    // Now select the appropriate 16 out of 18 bits from each field    
    packedIndices[0] = EXTRACT_BITS(packedIndices[0], 0, 16);
    packedIndices[1] = EXTRACT_BITS(packedIndices[1], 1, 17);
    packedIndices[2] = EXTRACT_BITS(packedIndices[2], 2, 18);

    float intMin = round(255.0f * min);
    float intMax = round(255.0f * max);
    float packedAnchors = intMax + 256.0f * intMin;
	
    return float4(packedAnchors, packedIndices[0], packedIndices[1], packedIndices[2]);
#elif DX_VERSION == 11
	uint packedIndices[3] = { 0, 0, 0 };
	for (i = 0; i < 6; i++)
	{
		packedIndices[0] |= uint(paletteIndices[i]) << (i * 3);
		packedIndices[1] |= uint(paletteIndices[5 + i]) << (i * 3);
		packedIndices[2] |= uint(paletteIndices[10 + i]) << (i * 3);
	}
	packedIndices[0] &= 0xffff;
	packedIndices[1] = (packedIndices[1] >> 1) & 0xffff;
	packedIndices[2] = (packedIndices[2] >> 2) & 0xffff;

	int maxEnd = int(max * 255.0f);
	int minEnd = int(min * 255.0f);
	if (is_signed)
	{
		maxEnd = (maxEnd - 128) & 0xff;
		minEnd = (minEnd - 128) & 0xff;
	}
	
	return uint2(
		maxEnd | (minEnd << 8) | (packedIndices[0] << 16),
		packedIndices[1] | (packedIndices[2] << 16));
#endif
}

#if DX_VERSION == 11
uint Pack565(in float3 rgb)
{
	uint3 irgb = uint3(rgb * float3(31, 63, 31));
	return irgb.b | (irgb.g << 5) | (irgb.r << 11);
}
#endif

#if DX_VERSION == 9
float4 EncodeDXT1Internal(float4 RGBA[16], float3 minRGBA, float3 maxRGBA)
#elif DX_VERSION == 11
uint2 EncodeDXT1Internal(float4 RGBA[16], float3 minRGBA, float3 maxRGBA)
#endif
{  
    // we'll just use min and max for anchors, 'cause it works well enough
    float3 anchor[2];
    anchor[0] = maxRGBA;
    anchor[1] = minRGBA;
    
    float3 RGBIncr = float3(31.0f, 63.0f, 31.0f);
#if DX_VERSION == 9	
    float3 RGBShift = float3(32.0f, 64.0f, 32.0f);
    float3 anchor565[2];
    float packedAnchor565[2];
    anchor565[0] = anchor[0];
    anchor565[0] *= RGBIncr;
    anchor565[0] = round(anchor565[0]);
    packedAnchor565[0] = anchor565[0].b + RGBShift.b * (anchor565[0].g + RGBShift.g * anchor565[0].r);
    anchor565[1] = anchor[1];
    anchor565[1] *= RGBIncr;
    anchor565[1] = round(anchor565[1]);
    packedAnchor565[1] = anchor565[1].b + RGBShift.b * (anchor565[1].g + RGBShift.g * anchor565[1].r);
#elif DX_VERSION == 11
	uint packedAnchor565[2] = { Pack565(maxRGBA), Pack565(minRGBA) };
#endif
        
    // For each input color, find the closest representable step along the line joining the anchors.
    float3 diag = anchor[1] - anchor[0];
    float stepInc = 3.0f / dot(diag, diag);
    float paletteIndices[16];
    paletteIndices[ 0] = round(dot(RGBA[ 0] - anchor[0], diag) * stepInc);
    paletteIndices[ 1] = round(dot(RGBA[ 1] - anchor[0], diag) * stepInc);
    paletteIndices[ 2] = round(dot(RGBA[ 2] - anchor[0], diag) * stepInc);
    paletteIndices[ 3] = round(dot(RGBA[ 3] - anchor[0], diag) * stepInc);
    paletteIndices[ 4] = round(dot(RGBA[ 4] - anchor[0], diag) * stepInc);
    paletteIndices[ 5] = round(dot(RGBA[ 5] - anchor[0], diag) * stepInc);
    paletteIndices[ 6] = round(dot(RGBA[ 6] - anchor[0], diag) * stepInc);
    paletteIndices[ 7] = round(dot(RGBA[ 7] - anchor[0], diag) * stepInc);
    paletteIndices[ 8] = round(dot(RGBA[ 8] - anchor[0], diag) * stepInc);
    paletteIndices[ 9] = round(dot(RGBA[ 9] - anchor[0], diag) * stepInc);
    paletteIndices[10] = round(dot(RGBA[10] - anchor[0], diag) * stepInc);
    paletteIndices[11] = round(dot(RGBA[11] - anchor[0], diag) * stepInc);
    paletteIndices[12] = round(dot(RGBA[12] - anchor[0], diag) * stepInc);
    paletteIndices[13] = round(dot(RGBA[13] - anchor[0], diag) * stepInc);
    paletteIndices[14] = round(dot(RGBA[14] - anchor[0], diag) * stepInc);
    paletteIndices[15] = round(dot(RGBA[15] - anchor[0], diag) * stepInc);
    
    // Remap palette indices according to DXT1 convention
    paletteIndices[ 0] = (paletteIndices[ 0] == 0.0f) ? 0.0f : (paletteIndices[ 0] == 3.0f) ? 1.0f : (paletteIndices[ 0] + 1);
    paletteIndices[ 1] = (paletteIndices[ 1] == 0.0f) ? 0.0f : (paletteIndices[ 1] == 3.0f) ? 1.0f : (paletteIndices[ 1] + 1);
    paletteIndices[ 2] = (paletteIndices[ 2] == 0.0f) ? 0.0f : (paletteIndices[ 2] == 3.0f) ? 1.0f : (paletteIndices[ 2] + 1);
    paletteIndices[ 3] = (paletteIndices[ 3] == 0.0f) ? 0.0f : (paletteIndices[ 3] == 3.0f) ? 1.0f : (paletteIndices[ 3] + 1);
    paletteIndices[ 4] = (paletteIndices[ 4] == 0.0f) ? 0.0f : (paletteIndices[ 4] == 3.0f) ? 1.0f : (paletteIndices[ 4] + 1);
    paletteIndices[ 5] = (paletteIndices[ 5] == 0.0f) ? 0.0f : (paletteIndices[ 5] == 3.0f) ? 1.0f : (paletteIndices[ 5] + 1);
    paletteIndices[ 6] = (paletteIndices[ 6] == 0.0f) ? 0.0f : (paletteIndices[ 6] == 3.0f) ? 1.0f : (paletteIndices[ 6] + 1);
    paletteIndices[ 7] = (paletteIndices[ 7] == 0.0f) ? 0.0f : (paletteIndices[ 7] == 3.0f) ? 1.0f : (paletteIndices[ 7] + 1);
    paletteIndices[ 8] = (paletteIndices[ 8] == 0.0f) ? 0.0f : (paletteIndices[ 8] == 3.0f) ? 1.0f : (paletteIndices[ 8] + 1);
    paletteIndices[ 9] = (paletteIndices[ 9] == 0.0f) ? 0.0f : (paletteIndices[ 9] == 3.0f) ? 1.0f : (paletteIndices[ 9] + 1);
    paletteIndices[10] = (paletteIndices[10] == 0.0f) ? 0.0f : (paletteIndices[10] == 3.0f) ? 1.0f : (paletteIndices[10] + 1);
    paletteIndices[11] = (paletteIndices[11] == 0.0f) ? 0.0f : (paletteIndices[11] == 3.0f) ? 1.0f : (paletteIndices[11] + 1);
    paletteIndices[12] = (paletteIndices[12] == 0.0f) ? 0.0f : (paletteIndices[12] == 3.0f) ? 1.0f : (paletteIndices[12] + 1);
    paletteIndices[13] = (paletteIndices[13] == 0.0f) ? 0.0f : (paletteIndices[13] == 3.0f) ? 1.0f : (paletteIndices[13] + 1);
    paletteIndices[14] = (paletteIndices[14] == 0.0f) ? 0.0f : (paletteIndices[14] == 3.0f) ? 1.0f : (paletteIndices[14] + 1);
    paletteIndices[15] = (paletteIndices[15] == 0.0f) ? 0.0f : (paletteIndices[15] == 3.0f) ? 1.0f : (paletteIndices[15] + 1);

#if DX_VERSION == 9    
    // Pack 32 2-bit palette indices into 2 16-bit unsigned integers
    float packedIndices[2];
    [flatten]
    if(packedAnchor565[0] == packedAnchor565[1])
    {
        // Handle case where anchors are equal
        packedIndices[0] = packedIndices[1] = 0.0f; 
    }
    else
    {
        packedIndices[0] =  paletteIndices[ 0] + 
                    4.0f * (paletteIndices[ 1] + 
                    4.0f * (paletteIndices[ 2] + 
                    4.0f * (paletteIndices[ 3] + 
                    4.0f * (paletteIndices[ 4] + 
                    4.0f * (paletteIndices[ 5] + 
                    4.0f * (paletteIndices[ 6] + 
                    4.0f * (paletteIndices[ 7]))))))); 
        packedIndices[1] =  paletteIndices[ 8] + 
                    4.0f * (paletteIndices[ 9] + 
                    4.0f * (paletteIndices[10] + 
                    4.0f * (paletteIndices[11] + 
                    4.0f * (paletteIndices[12] + 
                    4.0f * (paletteIndices[13] + 
                    4.0f * (paletteIndices[14] + 
                    4.0f * (paletteIndices[15]))))))); 
    }
        
    return float4(packedAnchor565[0], packedAnchor565[1], packedIndices[0], packedIndices[1]);
#elif DX_VERSION == 11
	uint packedIndices;
	if (packedAnchor565[0] == packedAnchor565[1])
	{
		packedIndices = 0;
	} else
	{
		packedIndices = 0;
		for (int i = 0; i < 16; i++)
		{
			packedIndices |= uint(paletteIndices[i]) << (i * 2);
		}
	}
	
	return uint2(
		packedAnchor565[0] | (packedAnchor565[1] << 16),
		packedIndices);
#endif
}

float4 ReinterpretCastUnsignedToSigned_16_16_16_16(float4 unsignedValue)
{
    // Return 4 signed 16-bit integers which are bitwise equivalent to the unsigned integer data.
    // This conversion is required for EDRAM writes, since the 64-bit render targets are all signed.
    // For the memexport pathway, it's slightly faster to simply use a natively unsigned type.
    // [2 vector ops]
    return unsignedValue - ((unsignedValue >= 32768.0f) ? 65536.0f : 0.0f); 
}

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


#if DX_VERSION == 9
void EncodeDXN(
	const in s_screen_vertex_output input,
	out float4 outColor0,
	out float4 outColor1)
#elif DX_VERSION == 11
uint4 EncodeDXN(const in s_screen_vertex_output input, in bool is_signed)
#endif
{
    float2 UV[16];
    
#if DX_VERSION == 9	
    float2 tiledTexcoord;
    tiledTexcoord.x = input.texcoord.x * 2;
    tiledTexcoord.y = input.texcoord.y;
    if (input.texcoord.x >= 0.5)
    {
		tiledTexcoord.x -= 1;
		LoadTexelsUVSecondTile(tiledTexcoord, UV);
    }
    else
    {
		LoadTexelsUVFirstTile(tiledTexcoord, UV);
    }
#elif DX_VERSION == 11
	uint2 block_coord = uint2(input.position.xy);
	
	uint texture_width, texture_height;
	ps_surface_sampler.t.GetDimensions(texture_width, texture_height);

	uint half_width = texture_width / 4;
	if (block_coord.x >= half_width)
	{
		LoadTexelsUVSecondTile(uint2(block_coord.x - half_width, block_coord.y), UV);
	} else
	{
		LoadTexelsUVFirstTile(block_coord, UV);
	}
#endif
    
    float2 minUV, maxUV;
    FindMinMaxUV(UV, minUV, maxUV);
    
    float uFloats[16], vFloats[16];
    for( int i = 0; i < 16; ++i )
    {
        uFloats[i] = UV[i].x;
        vFloats[i] = UV[i].y;
    }
	
#if DX_VERSION == 9	
    outColor0 = EncodeDXT5AInternal(uFloats, minUV.x, maxUV.x);
    outColor1 = EncodeDXT5AInternal(vFloats, minUV.y, maxUV.y);
    
    outColor0 = ReinterpretCastUnsignedToSigned_16_16_16_16(outColor0);
    outColor1 = ReinterpretCastUnsignedToSigned_16_16_16_16(outColor1);
#elif DX_VERSION == 11
	return uint4(
		EncodeDXT5AInternal(uFloats, minUV.x, maxUV.x, is_signed),
		EncodeDXT5AInternal(vFloats, minUV.y, maxUV.y, is_signed));
#endif
}

#if DX_VERSION == 9
void EncodeDXT5(
	const in s_screen_vertex_output input,
	out float4 outColor0,
	out float4 outColor1)
#elif DX_VERSION == 11
uint4 EncodeDXT5(const in s_screen_vertex_output input)
#endif
{
	// get the texels of the block
    float4 RGBA[16];
#if DX_VERSION == 9	
    LoadTexelsRGBA(input.texcoord, RGBA);
#elif DX_VERSION == 11
	uint2 block_coord = uint2(input.position.xy);
	LoadTexelsRGBA(block_coord, RGBA);
#endif
	
	// find the min and the max among them
    float4 minRGBA, maxRGBA;
    FindMinMaxRGBA(RGBA, minRGBA, maxRGBA);

#if DX_VERSION == 11
	uint2 outColor0, outColor1;
#endif

    // Slightly better results from repeating the texture fetches,
    // due to relief on register pressure
    //[isolate]
    {
        float alpha[16];
        for(int i = 0; i < 16; ++i)
        {
            alpha[i] = RGBA[i].a;
        }
        outColor0 = EncodeDXT5AInternal(alpha, minRGBA.w, maxRGBA.w);
    }
    //[isolate]
    {
        outColor1 = EncodeDXT1Internal(RGBA, minRGBA.xyz, maxRGBA.xyz);
    }
    
#if DX_VERSION == 9
    outColor0 = ReinterpretCastUnsignedToSigned_16_16_16_16(outColor0);
    outColor1 = ReinterpretCastUnsignedToSigned_16_16_16_16(outColor1);
#elif DX_VERSION == 11
	return uint4(outColor0, outColor1);
#endif
}

#if DX_VERSION == 9
void dxt5_ps(
	const in s_screen_vertex_output input, 
	out float4 outColor0: SV_Target0,
	out float4 outColor1: SV_Target1)
{
	EncodeDXT5(input, outColor0, outColor1);
}

void dxn_ps(
	const in s_screen_vertex_output input, 
	out float4 outColor0: SV_Target0,
	out float4 outColor1: SV_Target1)
{
	EncodeDXN(input, outColor0, outColor1);
}

void dxn_structure_sun_ps(
	const in s_screen_vertex_output input, 
	out float4 outColor0: SV_Target0,
	out float4 outColor1: SV_Target1)
{
	EncodeDXN(input, outColor0, outColor1);
}
#elif DX_VERSION == 11
uint4 dxt5_ps(const in s_screen_vertex_output input) : SV_Target
{
	return EncodeDXT5(input);
}

uint4 dxn_ps(const in s_screen_vertex_output input) : SV_Target
{
	return EncodeDXN(input, true);
}

uint4 dxn_structure_sun_ps(const in s_screen_vertex_output input) : SV_Target
{
	return EncodeDXN(input, false);
}
#endif

// compress DXT5
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(dxt5_ps());
	}
}

// compress DXN
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(dxn_ps());
	}
}

// compress DXN for structure sun channel
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(dxn_structure_sun_ps());
	}
}
