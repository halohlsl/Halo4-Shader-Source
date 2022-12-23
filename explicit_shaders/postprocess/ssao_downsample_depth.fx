#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


#define CONSTANT_NAME(n)		c##n
#define FLOAT_CONSTANT_NAME(n)	c##n
#include "ssao_registers.fxh"
#include "ssao_local_depth_registers.fxh"


LOCAL_SAMPLER2D(stencil_sampler, 1);


struct screen_output
{
	float4 position		:SV_Position;
	float2 texcoord		:TEXCOORD0;
};

screen_output default_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}
screen_output shadow_apply_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}
screen_output albedo_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}
screen_output static_probe_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}
screen_output shadow_generate_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}
screen_output active_camo_vs(s_screen_vertex IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	return OUT;
}



// box downsample with depth-conversion
float4 default_ps(screen_output IN) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord= IN.texcoord;

	float4 depths;
	asm
	{
		// box
		tfetch2D	depths.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY= -0.5
		tfetch2D	depths._r__, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.5, OffsetY= -0.5
		tfetch2D	depths.__r_, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY= +0.5
		tfetch2D	depths.___r, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.5, OffsetY= +0.5
	};

	// pack all four depths into the four color channels
	depths=		1.0f / (local_depth_constants.xxxx + depths * local_depth_constants.yyyy);
	return		depths;

#endif
}


// clover downsample with depth-conversion
float4 shadow_apply_ps(screen_output IN) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord= IN.texcoord;

	float4 depths;
	asm
	{
		// clover
		tfetch2D	depths.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY= -1.5
		tfetch2D	depths._r__, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -1.5, OffsetY= +0.5
		tfetch2D	depths.__r_, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.5, OffsetY= +1.5
		tfetch2D	depths.___r, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +1.5, OffsetY= -0.5
	};

	// pack all four depths into the four color channels
	depths=		1.0f / (local_depth_constants.xxxx + depths * local_depth_constants.yyyy);
	return		depths;

#endif
}



float calc_occlusion_samples(in float4 depths0, in float4 depths1, in float center_depth)
{
	const float4 sample_weights=	float4(1.0f, 1.0f, 1.0f, 1.0f);

	// improved method (ctchou)
	// the shadowing factor is a combination of:
	//   depression amount (how much the center sample is below the average of the two outer opposing depth samples)
	//   bounds amount (whether the nearest depth sample is within shadowing range of the center sample)
	// all depth comparisons are scaled by the distance to the center sample, so that the effect scales with distance

	#define FAR_TEST(depths)	saturate(1.1f - bounds_scale * (depths))

	float depression_scale=	25 / abs(center_depth);
	float4 depression=		saturate(depression_scale * (center_depth * 2.0 - (depths0 + depths1)));

	float bounds_scale=		4.0f / abs(center_depth);
	float4 bounds=			FAR_TEST(center_depth - min(depths0, depths1));

	return dot(depression * bounds * bounds, sample_weights);
}


// mask generate
float4 albedo_ps(screen_output IN) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord= IN.texcoord;

	float4 depths0;
	float4 depths1;
	float4 depths2;
	float4 depths3;
	float4 depths4;
	asm
	{
		tfetch2D	depths0, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY=  0.0
		tfetch2D	depths1, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY= -1.0
		tfetch2D	depths2, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +1.0, OffsetY=  0.0
		tfetch2D	depths3, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY= +1.0
		tfetch2D	depths4, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -1.0, OffsetY=  0.0
	};

    float4 depth_test= (depths0 < local_depth_constants.w) * (depths0 > local_depth_constants.z);
    float depth_pass= saturate(dot(depth_test, 1.0f));		// pass if any pixel passes
    float4    laplacian_y1=    depths0.barg + float4(depths1.ba, depths3.rg) - 2 * depths0.rgba;
    float4    laplacian_x1=    depths0.garb + float4(depths4.ga, depths2.rb) - 2 * depths0.rbga;

    float4 gradients=    sqrt(laplacian_x1.rgba * laplacian_x1.rgba + laplacian_y1.rbga * laplacian_y1.rbga) / depths0.rgba;

    float4 negatives=    saturate((laplacian_x1.rgba < 0) + (laplacian_y1.rbga < 0));		// either negative is ok

    float4 amounts=      saturate(30*gradients-225*gradients*gradients) * negatives;

//    float gradient_magnitude= max(gradients.x, max(gradients.y, max(gradients.z, gradients.w)));
//    float    amount=       saturate(30*gradient_magnitude-225*gradient_magnitude*gradient_magnitude);
//    float gradient_magnitude= dot(gradients, 0.25f);
//    float amount= max(amounts.x, max(amounts.y, max(amounts.z, amounts.w)));
//  float neg= dot(saturate(negatives)*gradients, 0.25f);

    float amount2= depth_pass * max(amounts.x, max(amounts.y, max(amounts.z, amounts.w)));

    return float4(amount2 - (10/255.0), amount2 - (10/255.0), amount2 - (10/255.0), 1.0f);

/*
    float4    laplacian_y1=    depths0.barg + float4(depths1.ba, depths3.rg) - 2 * depths0.rgba;
    float4    laplacian_x1=    depths0.garb + float4(depths4.ga, depths2.rb) - 2 * depths0.rbga;

    float4 gradients=    sqrt(laplacian_x1.rgba * laplacian_x1.rgba + laplacian_y1.rbga * laplacian_y1.rbga) / depths0.rgba;

    float gradient_magnitude= max(gradients.x, max(gradients.y, max(gradients.z, gradients.w)));

    float    amount=       saturate(40*gradient_magnitude-400*gradient_magnitude*gradient_magnitude);

    return float4(gradient_magnitude, amount, 0.0f, 0.0f);


/*
	float	center_depth=	(depths1.b	+	depths2.g	+	depths3.a	+	depths4.r) * 0.25f;


	float4	dx0=		depths2 - depths1;
	float4	dx1=		depths4 - depths3;
	float4	dy0=		depths3 - depths1;
	float4	dy1=		depths4 - depths2;
	float	average_dx=	dot(dx0 + dx1, 0.125f);
	float	average_dy=	dot(dy0 + dy1, 0.125f);

//	return float4(abs(average_dx), abs(average_dy), 0.0f, 0.0f) * 0.25f;

//	float	grad=		average_dx*average_dx + average_dy*average_dy;
	float	grad=		abs(average_dx) + abs(average_dy);

	float	amount=		saturate(20*grad-100*grad*grad);

//	grad /=		center_depth;

	return float4(amount, amount, 0.0f, 0.0f) * 0.25f;
*/

/*
	// calculate variance
	float	variance_dx=	pow(dx0-average_dx, 2) + pow(dx1-average_dx, 2);
	float	variance_dy=	pow(dy0-average_dy, 2) + pow(dy1-average_dy, 2);

	return float4(variance_dx, variance_dy, 0.0f, 0.0f);
*/

/*
	float	center_depth=	(depths1.b	+	depths2.g	+	depths3.a	+	depths4.r) * 0.25f;

//	float4	min_depth=	min(depths1, min(depths2, min(depths3, depths4)));
//	float4	max_depth=	max(depths1, max(depths2, max(depths3, depths4)));

	float4	d0=		float4(depths1.gr,	depths2.ra);
	float4	d1=		float4(depths4.ab,	depths3.bg);

//	float occlusion=	calc_occlusion_samples(d0, d1, center_depth);

	float occlusion=	0;

	occlusion	=		max(occlusion,	calc_occlusion_samples(d0, d1, depths1.b));
	occlusion	=		max(occlusion,	calc_occlusion_samples(d0, d1, depths2.g));
	occlusion	=		max(occlusion,	calc_occlusion_samples(d0, d1, depths3.a));
	occlusion	=		max(occlusion,	calc_occlusion_samples(d0, d1, depths4.r));

	return occlusion;
*/

/*
	// Convert depth values into camera space:
	float4 fragment_depth_camera_space=      mul( float4( texcoord, fragment_depth_post_projection, 1.0f ), transpose( texture_to_camera_matrix ));
		   fragment_depth_camera_space.xyz/= fragment_depth_camera_space.w;

	return fragment_depth_camera_space.z;
*/

#endif
}


// box downsample using max filter
float4 static_probe_ps(screen_output IN) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord= IN.texcoord;

	float4 value;
	asm
	{
		// box
		tfetch2D	value.r___, texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY= -0.5
		tfetch2D	value._r__, texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.5, OffsetY= -0.5
		tfetch2D	value.__r_, texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.5, OffsetY= +0.5
		tfetch2D	value.___r, texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY= +0.5
		max4		value, value
	};

	return value;
#endif
}


// cross expansion using max
float4 shadow_generate_ps(screen_output IN) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord= IN.texcoord;

	float4 value;
	float4 center;
	asm
	{
		// box
		tfetch2D	value.r___,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= +1.0, OffsetY=  0.0
		tfetch2D	value._r__,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= -1.0, OffsetY=  0.0
		tfetch2D	value.__r_,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY= +1.0
		tfetch2D	value.___r,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY= -1.0
		tfetch2D	center.r___, texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX=  0.0, OffsetY=  0.0
		max4		value, value
	};
	return max(value.x, center.x);
#endif
}

// move mask to stencil buffer
float4 active_camo_ps(screen_output IN) : SV_Target
{
#ifdef xenon
	float2 texcoord= IN.texcoord;
	float4 value;
	asm
	{
		tfetch2D	value.r___,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= 0.0, OffsetY=  0.0

		//	this second sample is really to just get around a 'bug' with pixel-kill and setting hi-stencil -- the lower right edges are always dropped.   so we're gonna expand down and to the right here
		tfetch2D	value._r__,  texcoord, depth_sampler, MagFilter= linear, MinFilter= linear, MipFilter= point, AnisoFilter= disabled, OffsetX= -0.5, OffsetY=  -0.5
	};
	value.r=	max(value.g, value.r);

	clip(value.r - 0.0012);			// kill when < 0	(value < 0.0012), for writing 1
#endif // xenon

	return 0.0f;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE albedo
{
	pass screen
	{
		SET_VERTEX_SHADER(albedo_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}

BEGIN_TECHNIQUE static_probe
{
	pass screen
	{
		SET_VERTEX_SHADER(static_probe_vs());
		SET_PIXEL_SHADER(static_probe_ps());
	}
}

BEGIN_TECHNIQUE shadow_generate
{
	pass screen
	{
		SET_VERTEX_SHADER(shadow_generate_vs());
		SET_PIXEL_SHADER(shadow_generate_ps());
	}
}

BEGIN_TECHNIQUE shadow_apply
{
	pass screen
	{
		SET_VERTEX_SHADER(shadow_apply_vs());
		SET_PIXEL_SHADER(shadow_apply_ps());
	}
}

BEGIN_TECHNIQUE active_camo
{
	pass screen
	{
		SET_VERTEX_SHADER(active_camo_vs());
		SET_PIXEL_SHADER(active_camo_ps());
	}
}
