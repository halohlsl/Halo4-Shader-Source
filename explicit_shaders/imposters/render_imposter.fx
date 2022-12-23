#define DISABLE_TANGENT_FRAME
#define DISABLE_VERTEX_COLOR
#define DISABLE_SHADOW_FRUSTUM_POS

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "lighting/sh.fxh"

#include "deform.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "render_imposter_registers.fxh"


// rename entry point of water passes
#define render_object_vs			default_vs
#define render_object_ps			default_ps
#define render_object_blend_vs		albedo_vs
#define render_object_blend_ps		albedo_ps
#define render_big_battle_object_vs		active_camo_vs
#define render_big_battle_object_ps		active_camo_ps

#define k_imposter_brightness_adjustment			k_ps_imposter_adjustment_constants.x


#define _big_battle_unit_vertex_budget			k_vs_big_battle_squad_constants.x
#define _big_battle_unit_vertex_range			k_vs_big_battle_squad_constants.y
#define _big_battle_squad_unit_start_index		k_vs_big_battle_squad_constants.z
#define _big_battle_squad_time_different		k_vs_big_battle_squad_constants.w


#if defined(xenon) || (DX_VERSION == 11) /* implementation of xenon version */

// The following defines the protocol for passing interpolated data between vertex/pixel shaders
struct s_imposter_interpolators
{
	float4 position			:SV_Position0;
	float3 normal			:NORMAL0;
	float3 diffuse			:COLOR0;
	float3 ambient			:COLOR1;
	float4 specular_shininess		:COLOR2;
	float4 change_colors_of_diffuse		:TEXCOORD0;
	float4 change_colors_of_specular	:TEXCOORD1;
	float3 view_vector		:TEXCOORD2;
};

struct s_big_battle_interpolators
{
	float4 position						:SV_Position0;
	float3 normal						:NORMAL0;
	float3 diffuse						:COLOR0;
	float3 ambient						:COLOR1;
	float4 specular_shininess			:COLOR2;
	float3 view_vector					:TEXCOORD1;
	float3 position_ws					:TEXCOORD2;
};

float4 render_object_vs_only(in s_object_imposter_vertex vertex) : SV_Position0
{
	s_imposter_interpolators output = (s_imposter_interpolators)0;
	float4 local_to_world_transform[3];
	apply_transform(deform_object_imposter, vertex, output, local_to_world_transform, output.position);
	return output.position;
}

s_imposter_interpolators render_object_vs(
	in s_object_imposter_vertex vertex)
{
	s_imposter_interpolators OUT = (s_imposter_interpolators)0;
	float4 local_to_world_transform[3];
	//transform_identity(local_to_world_transform);
	//DecompressPosition(vertex.position);
	//world_projection_transform(vertex, local_to_world_transform, OUT.position);
	//OUT.normal = vertex.normal;
	//OUT.view_vector.xyz = vertex.position.xyz - vs_view_camera_position.xyz;
	apply_transform(deform_object_imposter, vertex, OUT, local_to_world_transform, OUT.position);

	// world space direction to eye/camera
	OUT.view_vector = -OUT.view_vector;

	// out diffuse/ambient/change_colors
	OUT.diffuse= vertex.diffuse * vertex.diffuse;
	OUT.ambient= vertex.ambient * vertex.ambient;
	OUT.specular_shininess.rgb = vertex.specular_shininess.rgb * vertex.specular_shininess.rgb;
	OUT.specular_shininess.a = vertex.specular_shininess.a;

	OUT.change_colors_of_diffuse= vertex.change_colors_of_diffuse * vertex.change_colors_of_diffuse;
	OUT.change_colors_of_specular= vertex.change_colors_of_specular * vertex.change_colors_of_specular;

	return OUT;
}


s_big_battle_interpolators render_big_battle_object_vs(
	in uint index: SV_VertexID)
{
	float unit_index= floor(index/_big_battle_unit_vertex_budget);
	float old_vertex_index= index - unit_index*_big_battle_unit_vertex_budget;
	float vertex_index= min(old_vertex_index, _big_battle_unit_vertex_range);


	float4 position, normal;
	float4 diffuse, ambient, specular_shininess;
#ifdef xenon
	// get vertex data
	asm
	{
		vfetch position, vertex_index, position0
		vfetch normal, vertex_index, normal0

		vfetch diffuse, vertex_index, texcoord1
		vfetch ambient, vertex_index, texcoord2
		vfetch specular_shininess, vertex_index, texcoord3
	};
#else
	position = 0;
	normal = 0;
	diffuse = 0;
	ambient = 0;
	specular_shininess = 0;
#endif

	// ## jowaters --	Reach big battle impostors are way too dark in our lighting, brighten them.
	//					may need to revisit after I get Midnight models working with big battle impostors
	diffuse *= 8.0f;

	// get unit data
	float4 unit_position_scale;
	float4 unit_foward, unit_left, unit_up;
	float4 unit_velocity;

	unit_index+= _big_battle_squad_unit_start_index;
#ifdef xenon	
	asm
	{
		vfetch unit_velocity, unit_index, tangent0
		vfetch unit_position_scale, unit_index, binormal0
		vfetch unit_foward, unit_index, color0
		vfetch unit_left, unit_index, color1

	};
#else
	unit_velocity = 0;
	unit_position_scale = 0;
	unit_foward = 0;
	unit_left = 0;
#endif

	unit_up.xyz= cross(unit_foward, unit_left);

	// decompress position
	position.xyz = position.xyz * vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;

	// transform position and normal to world space
	float3 new_position=
		unit_foward*position.x +
		unit_left*position.y +
		unit_up*position.z;
	new_position*= unit_position_scale.w;		// scale
	new_position+= unit_position_scale.xyz;		// offset
	new_position+= unit_velocity.xyz*_big_battle_squad_time_different;

	float3 new_normal=
		unit_foward*normal.x +
		unit_left*normal.y +
		unit_up*normal.z;

	// output data to pixel shader
	s_big_battle_interpolators OUT;
	{
		OUT.position= mul(float4(new_position.xyz, 1.f), vs_view_view_projection_matrix);
		OUT.normal= new_normal.xyz;

		OUT.diffuse= diffuse.rgb * diffuse.rgb;
		OUT.ambient= ambient.rgb * ambient.rgb;
		OUT.specular_shininess= specular_shininess;
		OUT.specular_shininess.rgb*= OUT.specular_shininess.rgb;
		OUT.view_vector= vs_view_camera_position - new_position;
		OUT.position_ws= new_position;
	}

	if (old_vertex_index >= _big_battle_unit_vertex_range)
	{
		OUT.position= k_vs_hidden_from_compiler;
	}

	return OUT;
}


s_imposter_interpolators render_object_blend_vs(
	in s_object_imposter_vertex vertex)
{
	s_imposter_interpolators OUT= render_object_vs(vertex);
	return OUT;
}


struct imposter_pixel
{
	float4 color : SV_Target0;			// albedo color (RGB) + specular mask (A)
	float4 normal : SV_Target1;			// normal (XYZ)
};


imposter_pixel convert_to_imposter_target(in float4 color, in float3 normal, in float normal_alpha_spec_type)
{
	imposter_pixel result;

	result.color= PackRGBk(color.rgb);

	result.normal.xy = EncodeWorldspaceNormal(normal);
	result.normal.z = 0.0f;
	result.normal.w = normal_alpha_spec_type;		// alpha channel for normal buffer (either blend factor, or specular type)

	return result;
}

#define pi 3.14159265358979323846
#define one_over_pi			0.32f

float imposter_convertBandwidth2TextureCoord(float fFandWidth)
{
    return fFandWidth;
}

float3 ImposterCalcDiffuse(float3 normal, float4 lighting[4])
{
	return LinearSHIrradianceScalar(normal, lighting[0], lighting[1].rgb, float3(0,0,1), false) +
		   LinearSHIrradianceScalar(normal, lighting[2], lighting[3].rgb, float3(0,0,1), false);
}

float3 calculate_change_color(const float4 coefficients)
{
	float3 change =
		(1.0f - coefficients.x + coefficients.x*ps_material_object_parameters[0].rgb) *
		(1.0f - coefficients.y + coefficients.y*ps_material_object_parameters[1].rgb) *
		(1.0f - coefficients.z + coefficients.z*ps_material_object_parameters[2].rgb) *
		(1.0f - coefficients.w + coefficients.w*ps_material_object_parameters[3].rgb);
	return change;
}

float3 calculate_spec(float3 lightdir, float3 lightintensity, float3 view_dir, float3 normal, float3 speccolor, float shininess, float mask)
{
	float3 half_dir = normalize(lightdir + view_dir);
	float n_dot_h = saturate(dot(normal, half_dir));
	return lightintensity * pow(n_dot_h, shininess) * mask * speccolor;
}

imposter_pixel render_object_ps( s_imposter_interpolators IN )
{	
	float invpi = 0.31830988618379067153803535746773;

	float3 view_dir = normalize(IN.view_vector);
	float3 normal = normalize(IN.normal);
	float n_dot_v = saturate(dot(normal, view_dir));
	float3 ws_pos = ps_camera_position.xyz - IN.view_vector.xyz;

	float3 diffuse_radiance = ImposterCalcDiffuse(normal, ps_model_vmf_lighting);
	diffuse_radiance += PerformQuadraticSHCosineConvolution(ps_model_sh_lighting, normal);

	float analytical_mask = ps_model_vmf_lighting[1].a;
	float3 analytical_dir;
	float3 analytical_intensity;
	bool sun_enabled = dot(ps_floating_shadow_light_intensity.xyz, ps_floating_shadow_light_intensity.xyz) > 0.0f ? true : false;

	if (sun_enabled)
	{
		analytical_dir = -ps_floating_shadow_light_direction.xyz;
		analytical_intensity = ps_floating_shadow_light_intensity.xyz;
	}
	else
	{
		analytical_dir = normalize(ps_analytic_light_position.xyz - ws_pos);
		analytical_intensity = ps_analytic_light_intensity.xyz;
	}

	float analytical_cosine = saturate(dot(normal.xyz, analytical_dir));
	diffuse_radiance += analytical_cosine * analytical_mask * analytical_intensity * invpi;

	const float3 diffuse = IN.diffuse * calculate_change_color(IN.change_colors_of_diffuse);
	const float3 ambient = IN.ambient;

	const float shininess = IN.specular_shininess.w * 100;
	const float3 specular = IN.specular_shininess.rgb * calculate_change_color(IN.change_colors_of_specular);

	// specular
	float3 sunspec = calculate_spec(analytical_dir, analytical_intensity, view_dir, normal, specular, shininess, analytical_mask);
	float3 dirspec = calculate_spec(normalize(ps_model_vmf_lighting[0].xyz), ps_model_vmf_lighting[1].xyz, view_dir, normal, specular, shininess, 1 - analytical_mask);

	// put together
	float4 out_color;
	out_color.rgb = sunspec + dirspec + diffuse*diffuse_radiance + ambient;
	out_color.rgb *= k_imposter_brightness_adjustment;	// this is the content editable adjustment
	out_color.w = 0;

	return convert_to_imposter_target(out_color, normal, 1.0);
}

float4 render_object_blend_ps(
	s_imposter_interpolators IN,
	in SCREEN_POSITION_INPUT(vpos)) :SV_Target0
{
	imposter_pixel OUT= render_object_ps(IN);


	float4 shadow;
#ifdef xenon	
	asm {
		tfetch2D shadow, vpos, ps_view_shadow_mask, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#else
	shadow = ps_view_shadow_mask.Load(int3(vpos.xy, 0));
#endif	

	float alpha= k_ps_imposter_blend_alpha.a;
	float4 out_color;
	out_color.rgb= OUT.color.rgb * (1.0f - alpha) * shadow.a;
#ifdef xenon
	out_color.a= alpha * 0.03125f;	// scale by 1/32
#else
	out_color.a= alpha;
#endif
	return out_color;
}

imposter_pixel render_big_battle_object_ps(
	s_big_battle_interpolators IN) :SV_Target0
{
	float3 view_dir= normalize(IN.view_vector);
	float3 normal= normalize(IN.normal);
	float n_dot_v= saturate(dot(normal, view_dir));

	float3 diffuse_radiance= ImposterCalcDiffuse(normal, ps_model_vmf_lighting);

	float analytical_mask= ps_model_vmf_lighting[0].a;

	float3 analytical_radiance=
		saturate(dot(ps_floating_shadow_light_direction, normal)) *
		ps_floating_shadow_light_intensity *
		ps_model_vmf_lighting[2].w / pi;
	float3 bounce_radiance= 0;//saturate(dot(k_ps_bounce_light_direction, normal))*k_ps_bounce_light_intensity/pi;
	diffuse_radiance+= analytical_mask * (analytical_radiance + bounce_radiance);

	float3 half_dir= normalize( ps_floating_shadow_light_direction + view_dir );
	float n_dot_h= saturate(dot(normal, half_dir));

	const float shininess=
		IN.specular_shininess.w * 100;	// shininess

	// caculated diffuse and ambient
	const float3 diffuse= IN.diffuse;
	const float3 ambient= IN.ambient;
	const float3 specular= IN.specular_shininess.rgb;

	const float3 specular_radiance= ps_floating_shadow_light_intensity * pow(n_dot_h, shininess);

	float4 out_color;
	out_color.rgb=
		specular*specular_radiance*analytical_mask +
		diffuse*diffuse_radiance +
		ambient;

	out_color.rgb*= k_imposter_brightness_adjustment;

	out_color.w= 0;

	return convert_to_imposter_target(out_color, normal, 1.0);
}


#else /* implementation of pc version */

struct s_imposter_interpolators
{
	float4 position	:SV_Position0;
};

s_imposter_interpolators render_object_vs()
{
	s_imposter_interpolators OUT;
	OUT.position= 0.0f;
	return OUT;
}

float4 render_object_vs_only(in s_object_imposter_vertex vertex) : SV_Position0
{
	return 0;
}

float4 render_object_ps(s_imposter_interpolators IN) :SV_Target0
{
	return float4(0,1,2,3);
}

s_imposter_interpolators render_object_blend_vs()
{
	s_imposter_interpolators OUT;
	OUT.position= 0.0f;
	return OUT;
}

float4 render_object_blend_ps(s_imposter_interpolators IN) :SV_Target0
{
	return float4(0,1,2,3);
}

void render_big_battle_object_vs(
	in float4 position	:POSITION0,
	in float4 color		:TEXCOORD1,
	out float4 out_position	: SV_Position,
	out float3 out_color	: TEXCOORD0)
{
	const float3 unit_foward= k_vs_big_battle_squad_foward.xyz;
	const float3 unit_left= k_vs_big_battle_squad_left.xyz;
	const float3 unit_up= cross(unit_foward, unit_left);

	const float3 unit_position= k_vs_big_battle_squad_positon_scale.xyz;
	const float unit_scale= k_vs_big_battle_squad_positon_scale.w;

	const float3 unit_velocity= k_vs_big_battle_squad_velocity.xyz;

	//swizzle position for xenon data
	position.xyz= position.wzy;

	// decompress position
	position.xyz = position.xyz * vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;

	// transform position and normal to world space
	float3 new_position=
		unit_foward*position.x +
		unit_left*position.y +
		unit_up*position.z;

	new_position*= unit_scale;
	new_position+= unit_position;
	new_position+= unit_velocity.xyz*_big_battle_squad_time_different;

	out_position= mul(float4(new_position.xyz, 1.f), vs_view_view_projection_matrix);
	out_color= color.wzy;
}

float4 render_big_battle_object_ps(
	in float4 screen_position : SV_Position,
	in float3 color :TEXCOORD0) :SV_Target0
{
	return float4(color.rgb, 1);
}

#endif //pc/xenon

// end of rename marco
#undef render_object_vs
#undef render_object_ps
#undef IMPOSTER_CLOUD_SAMPLING

BEGIN_TECHNIQUE _default
{
	pass object_imposter
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE albedo
{
	pass object_imposter
	{
		SET_VERTEX_SHADER(albedo_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}

BEGIN_TECHNIQUE active_camo
{
	pass object_imposter
	{
		SET_VERTEX_SHADER(active_camo_vs());
		SET_PIXEL_SHADER(active_camo_ps());
	}
}

BEGIN_TECHNIQUE shadow_generate
{
	pass object_imposter
	{
		SET_VERTEX_SHADER(render_object_vs_only());
	}
}

