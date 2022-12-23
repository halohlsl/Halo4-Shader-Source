#include "core/core.fxh"
#include "fx/fx_parameters.fxh"
#include "fx/fx_functions.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(detail_map, "Detail Texture", "Detail Texture", "shaders/default_bitmaps/bitmaps/alpha_white.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_black_point, "Detail Black Point", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_white_point, "Detail White Point", "", 0, 1, float(1.0));
#include "used_float.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in float2 texcoord)
{
	float4 color;
	
	color = sample2DGamma(basemap, transform_texcoord(texcoord, basemap_transform));
	float detail = sample2DGamma(detail_map, transform_texcoord(texcoord, detail_map_transform)).r;

	color.rgb *= ApplyBlackPointAndWhitePoint(detail_black_point, detail_white_point, detail);

	return color;
}

#include "fx/light_cone_techniques.fxh"