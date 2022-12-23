#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "shadow_generate_variance_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

void default_ps(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
    float depth = sample2D(ps_texture_sampler, input.texcoord.xy).r;
    outColor = float4(depth, depth*depth, 0.0f, 0.0f);
}

void HorizontalBlurVariancePS(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
    // Fetch a row of 5 pixels from the D24S8 depth map
    float4 DepthSamples0123;
    float4 DepthSamples4___;
#if defined(xenon)
	float2 texcoord = input.texcoord.xy;
    asm
    {
        tfetch2D DepthSamples0123.x___, texcoord, ps_texture_sampler, OffsetX = -2.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123._x__, texcoord, ps_texture_sampler, OffsetX = -1.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123.__x_, texcoord, ps_texture_sampler, OffsetX = -0.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123.___x, texcoord, ps_texture_sampler, OffsetX = +1.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples4___.x___, texcoord, ps_texture_sampler, OffsetX = +2.0, MinFilter=point, MagFilter=point
    };
#elif (DX_VERSION == 11)
	DepthSamples0123.x = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(-2, 0)).x;
	DepthSamples0123.y = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(-1, 0)).x;
	DepthSamples0123.z = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(0, 0)).x;
	DepthSamples0123.w = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(1, 0)).x;
	DepthSamples4___.x = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(2, 0)).x;
#endif	
    
#if defined(xenon) || (DX_VERSION == 11)	
    // Do the Gaussian blur (using a 5-tap filter kernel of [ 1 4 6 4 1 ] )
    float z  = dot(DepthSamples0123.xyzw,  float4(ps_gaussian_parameters[0].x, ps_gaussian_parameters[0].y, ps_gaussian_parameters[0].z, ps_gaussian_parameters[0].y)) + DepthSamples4___.x * (ps_gaussian_parameters[0].x); // weight them and sum up

    DepthSamples0123.xyzw = DepthSamples0123.xyzw * DepthSamples0123.xyzw; // square them
    DepthSamples4___.x    = DepthSamples4___.x    * DepthSamples4___.x;
    float z2 = dot(DepthSamples0123.xyzw,  float4(ps_gaussian_parameters[0].x, ps_gaussian_parameters[0].y, ps_gaussian_parameters[0].z, ps_gaussian_parameters[0].y)) + DepthSamples4___.x * (ps_gaussian_parameters[0].x); // weight the squares and sum up
    
    outColor = float4(z, z2, 0, 0);
#else
	outColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
}

void VerticalBlurVariancePS(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
#if defined(xenon) || (DX_VERSION == 11)
    float4 t0, t1;
	float2 texcoord[4];
	
	// the parameters act like Y offsets so we can scale down the size of the blur if we want
	texcoord[0] = float2(input.texcoord.x, input.texcoord.y + ps_gaussian_parameters[1].x);
	texcoord[1] = float2(input.texcoord.x, input.texcoord.y + ps_gaussian_parameters[1].y);
	texcoord[2] = float2(input.texcoord.x, input.texcoord.y + ps_gaussian_parameters[1].z);
	texcoord[3] = float2(input.texcoord.x, input.texcoord.y + ps_gaussian_parameters[1].w);

#if defined(xenon)
    asm
    {
        tfetch2D t0.xy__, texcoord[0], ps_texture_sampler, MinFilter=linear, MagFilter=linear
        tfetch2D t0.__xy, texcoord[1], ps_texture_sampler, MinFilter=linear, MagFilter=linear
        tfetch2D t1.xy__, texcoord[2], ps_texture_sampler, MinFilter=linear, MagFilter=linear
        tfetch2D t1.__xy, texcoord[3], ps_texture_sampler, MinFilter=linear, MagFilter=linear
    };
#else
	t0.xy = sample2D(ps_texture_sampler, texcoord[0]).xy;
	t0.zw = sample2D(ps_texture_sampler, texcoord[1]).xy;
	t1.xy = sample2D(ps_texture_sampler, texcoord[2]).xy;
	t1.zw = sample2D(ps_texture_sampler, texcoord[3]).xy;
#endif
	    
    // Sum results with Gaussian weights
    float z  = dot(float4(t0.x, t0.z, t1.x, t1.z), float4(2.0/16, 6.0/16, 6.0/16, 2.0/16));
    float z2 = dot(float4(t0.y, t0.w, t1.y, t1.w), float4(2.0/16, 6.0/16, 6.0/16, 2.0/16));
    outColor = float4(z, z2, 0, 0);
#else
	outColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
}


void BlobBlurVariancePS(const in s_screen_vertex_output input, out float4 outColor: SV_Target0)
{
    // Fetch a row of 5 pixels from the D24S8 depth map
    float4 DepthSamples0123;
    float4 DepthSamples4567;
    float4 DepthSamples8___;
#if defined(xenon)
	float2 texcoord = input.texcoord.xy;
    asm
    {
        tfetch2D DepthSamples0123.x___, texcoord, ps_texture_sampler, OffsetX = -1.0, OffsetY = -1.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123._x__, texcoord, ps_texture_sampler, OffsetX =  0.0, OffsetY = -1.0, MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123.__x_, texcoord, ps_texture_sampler, OffsetX = +1.0, OffsetY = -1.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples0123.___x, texcoord, ps_texture_sampler, OffsetX = -1.0, OffsetY =  0.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples4567.x___, texcoord, ps_texture_sampler, OffsetX =  0.0, OffsetY =  0.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples4567._x__, texcoord, ps_texture_sampler, OffsetX = +1.0, OffsetY =  0.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples4567.__x_, texcoord, ps_texture_sampler, OffsetX = -1.0, OffsetY = +1.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples4567.___x, texcoord, ps_texture_sampler, OffsetX =  0.0, OffsetY = +1.0,  MinFilter=point, MagFilter=point
        tfetch2D DepthSamples8___.x___, texcoord, ps_texture_sampler, OffsetX = +1.0, OffsetY = +1.0,  MinFilter=point, MagFilter=point
    };
#elif DX_VERSION == 11
	DepthSamples0123.x = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(-1, -1)).x;
	DepthSamples0123.y = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(0, -1)).x;
	DepthSamples0123.z = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(1, -1)).x;
	DepthSamples0123.w = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(-1, 0)).x;
	DepthSamples4567.x = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(0, 0)).x;
	DepthSamples4567.y = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(1, 0)).x;
	DepthSamples4567.z = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(-1, 1)).x;
	DepthSamples4567.w = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(0, 1)).x;
	DepthSamples8___.x = ps_texture_sampler.t.Sample(ps_texture_sampler.s, input.texcoord, int2(1, 1)).x;
#endif
    
#if defined(xenon) || (DX_VERSION == 11)
    // Do the Gaussian blur (using a 5-tap filter kernel of [ 1 4 6 4 1 ] )
    float z  = 	dot(DepthSamples0123.xyzw,  float4(1.0/16.0, 2.0/16.0, 1.0/16.0, 2.0/16.0)) +
				dot(DepthSamples4567.xyzw,  float4(4.0/16.0, 2.0/16.0, 1.0/16.0, 2.0/16.0)) +
				DepthSamples8___.x * (1.0/16.0); // weight them and sum up

    DepthSamples0123.xyzw = DepthSamples0123.xyzw * DepthSamples0123.xyzw; // square them
    DepthSamples4567.xyzw = DepthSamples4567.xyzw * DepthSamples4567.xyzw; // square them
    DepthSamples8___.x    = DepthSamples8___.x    * DepthSamples8___.x;
	
    float z2 = 	dot(DepthSamples0123.xyzw,  float4(1.0/16.0, 2.0/16.0, 1.0/16.0, 2.0/16.0)) +
				dot(DepthSamples4567.xyzw,  float4(4.0/16.0, 2.0/16.0, 1.0/16.0, 2.0/16.0)) +
				DepthSamples8___.x * (1.0/16.0);// weight the squares and sum up
    
    outColor = float4(z, z2, 0, 0);
#else
	outColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
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

// regular
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


// horiz blur
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(HorizontalBlurVariancePS());
	}
}

// vert blur
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(VerticalBlurVariancePS());
	}
}

// blob blur
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(BlobBlurVariancePS());
	}
}