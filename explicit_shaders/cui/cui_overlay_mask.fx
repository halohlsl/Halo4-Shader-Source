#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader


#define k_angle k_cui_pixel_shader_scalar0
#define k_offsetX k_cui_pixel_shader_scalar1
#define k_offsetY k_cui_pixel_shader_scalar2
#define k_tileMode k_cui_pixel_shader_scalar3

#define k_scale k_cui_pixel_shader_color0
#define k_flipAxes k_cui_pixel_shader_color1

// ### HACK v-miroll: These should really be int's for performance sake. That would allow the conditional in the pixel shader
// to use a switch statement instead of a series of if's. For some reason, Cui shaders throw errors when using int's, though.
// You win this round, Cui.
#define k_tileModeClamp 0
#define k_tileModeWrap 1
#define k_tileModeMirror 2

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color0 = cui_tex2D(input.texcoord);

	// Convert from tiled tiled coordinates to 0..1
	float2 maskTexcoord = (input.texcoord - k_cui_pixel_shader_bounds.xz) /
		(k_cui_pixel_shader_bounds.yw - k_cui_pixel_shader_bounds.xz);

	// Convert from local coordinates to authored bounds
	maskTexcoord = (maskTexcoord - k_cui_pixel_shader_authored_bounds.xy) /
		(k_cui_pixel_shader_authored_bounds.zw - k_cui_pixel_shader_authored_bounds.xy);

	maskTexcoord = (maskTexcoord * k_flipAxes.xz) + k_flipAxes.yw;

#ifdef xenon
	float4 gradients;
	asm {
		getGradients gradients, maskTexcoord, source_sampler0
	};
#elif DX_VERSION == 11
	float4 gradients = GetGradients(maskTexcoord);
#else
	float4 gradients = float4(1.0f, 0.0f, 0.0f, 1.0f);
#endif

	// Offset the origin of the gradient by (k_offsetX, k_offsetY) in screenspace pixels
	maskTexcoord += (-k_offsetX * gradients.xy) + (-k_offsetY * gradients.zw);

	// Scale and rotate the maskTexcoord about it's center
	float2 rotatedTexcoord = float2(
		dot(maskTexcoord-0.5, float2(cos(k_angle), -sin(k_angle))),
		dot(maskTexcoord-0.5, float2(sin(k_angle), cos(k_angle))));

	rotatedTexcoord *= k_scale.xy;
	rotatedTexcoord += float2(0.5, 0.5);

	if (k_tileMode == k_tileModeWrap)
	{
		float2 uvTile;
		rotatedTexcoord = modf(rotatedTexcoord, uvTile);
		rotatedTexcoord = lerp(rotatedTexcoord, float2(1.0, 1.0) + rotatedTexcoord, step(rotatedTexcoord, float2(0.0, 0.0)));
	}
	else if (k_tileMode == k_tileModeMirror)
	{
		float2 uvTile;
		rotatedTexcoord = abs(modf(rotatedTexcoord, uvTile));

		uvTile = fmod(abs(uvTile), float2(2.0, 2.0));
		rotatedTexcoord = lerp(rotatedTexcoord, float2(1.0,1.0)-rotatedTexcoord, step(float2(1.0, 1.0), uvTile));
	}

	rotatedTexcoord = clamp(rotatedTexcoord, float2(0.0, 0.0), float2(1.0, 1.0));

	float4 color1 = cui_tex2D_secondary(rotatedTexcoord);

	float4 color = color0 * color1;
	color.a = 1 - (1 - color0.a) * (1 - color1.a);

	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint));

	return color*ps_scale;
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
