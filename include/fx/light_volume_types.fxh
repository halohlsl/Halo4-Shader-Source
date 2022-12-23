#if !defined(__LIGHT_VOLUME_TYPES_FXH)
#define __LIGHT_VOLUME_TYPES_FXH

struct LightVolumeInterpolatorsInternal
{
	float4 position0	:SV_Position0;
	float4 color0		:COLOR0;
	float4 texcoord0	:TEXCOORD0;

#if defined(LIGHT_VOLUME_3D_TEXTURE)
	float4 texcoord1	:TEXCOORD1;
#endif // defined(LIGHT_VOLUME_3D_TEXTURE)
};

struct LightVolumeInterpolatedValues
{
    float4 position;
    float2 texcoord;
	float2 screenCoord;
    float4 color; // COLOR semantic will not clamp to [0,1].
	float depth;
	
#if defined(LIGHT_VOLUME_3D_TEXTURE)
	float volumeTexcoordZ;
#endif // defined(LIGHT_VOLUME_3D_TEXTURE)
};

LightVolumeInterpolatorsInternal WriteLightVolumeInterpolators(LightVolumeInterpolatedValues values)
{
	LightVolumeInterpolatorsInternal interpolators;
	
	values.position.xyzw /= abs(values.position.w); // Bungie sez: turn off perspective correction
	
	interpolators.position0 = values.position;
	interpolators.texcoord0 = float4(values.texcoord.xy, values.screenCoord);

#if defined(LIGHT_VOLUME_3D_TEXTURE)
	interpolators.texcoord1 = float4(values.volumeTexcoordZ, values.depth, 0.0, 0.0);
	interpolators.color0 = values.color;
#else // defined(LIGHT_VOLUME_3D_TEXTURE)
	interpolators.color0 = float4(values.color.rgb * values.color.w, values.depth); // multiply in alpha to save a slot
#endif // defined(LIGHT_VOLUME_3D_TEXTURE)

	return interpolators;
}

LightVolumeInterpolatedValues ReadLightVolumeInterpolators(LightVolumeInterpolatorsInternal interpolators)
{
	LightVolumeInterpolatedValues values;
	
	values.position = interpolators.position0;
	values.texcoord = interpolators.texcoord0.xy;
	values.screenCoord = interpolators.texcoord0.zw;

#if defined(LIGHT_VOLUME_3D_TEXTURE)
	values.volumeTexcoordZ = interpolators.texcoord1.x;
	values.depth = interpolators.texcoord1.y;
	values.color = interpolators.color0;
#else // defined(LIGHT_VOLUME_3D_TEXTURE)
	values.color = float4(interpolators.color0.xyz, 1.0f);
	values.depth = interpolators.color0.w;
#endif // defined(LIGHT_VOLUME_3D_TEXTURE)

	return values;
}

#endif 	// !defined(__LIGHT_VOLUME_TYPES_FXH)