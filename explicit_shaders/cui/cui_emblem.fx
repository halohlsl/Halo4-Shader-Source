#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"
#include "../utility/player_emblem.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4	emblem_pixel = calc_emblem(input.texcoord, true);

	return emblem_pixel * ps_scale;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
