#if !defined(__TRACER_TYPES_FXH)
#define __TRACER_TYPES_FXH

struct TracerInterpolatorsInternal
{
	float4 position0	:SV_Position0;
	float4 color0		:COLOR0;
	float4 texcoord0	:TEXCOORD0;
#if defined(RENDER_DISTORTION)
	float4 texcoord1	:TEXCOORD1;
	float4 texcoord2	:TEXCOORD2;
#elif defined(TRACER_DEPTH)
	float4 texcoord1 : TEXCOORD1;
#endif
};

struct TracerInterpolatedValues
{
    float4 position;
    float4 color; // COLOR semantic will not clamp to [0,1].
    float2 texcoord;
    float blackPoint; // avoid using interpolator for constant-per-profile value?
    float palette; // avoid using interpolator for constant-per-profile value?
#if defined(RENDER_DISTORTION)
	float3 tangent;
	float3 binormal;
	float depth;
#elif defined(TRACER_DEPTH)
	float depth;
#endif // defined(TRACER_DEPTH)
};

TracerInterpolatorsInternal WriteTracerInterpolators(TracerInterpolatedValues tracerValues)
{
	TracerInterpolatorsInternal interpolators;
	
	interpolators.position0 = tracerValues.position;
	interpolators.color0 = tracerValues.color;
	interpolators.texcoord0 = float4(tracerValues.texcoord, tracerValues.blackPoint, tracerValues.palette);

#if defined(RENDER_DISTORTION)
	interpolators.texcoord1 = float4(tracerValues.tangent, tracerValues.depth);
	interpolators.texcoord2 = float4(tracerValues.binormal, 0.0f);
#elif defined(TRACER_DEPTH)
	interpolators.texcoord1 = float4(0.0f, 0.0f, 0.0f, tracerValues.depth);
#endif

	return interpolators;
}

TracerInterpolatedValues ReadTracerInterpolators(TracerInterpolatorsInternal interpolators)
{
	TracerInterpolatedValues tracerValues;
	
	tracerValues.position = interpolators.position0;
	tracerValues.color = interpolators.color0;
	tracerValues.texcoord = interpolators.texcoord0.rg;
	tracerValues.blackPoint = interpolators.texcoord0.b;
	tracerValues.palette = interpolators.texcoord0.a;
	
#if defined(RENDER_DISTORTION)
	tracerValues.tangent = interpolators.texcoord1.rgb;
	tracerValues.depth = interpolators.texcoord1.a;
	tracerValues.binormal = interpolators.texcoord2.rgb;
#elif defined(TRACER_DEPTH)
	tracerValues.depth = interpolators.texcoord1.a;
#endif

	return tracerValues;
}

#endif 	// !defined(__TRACER_TYPES_FXH)