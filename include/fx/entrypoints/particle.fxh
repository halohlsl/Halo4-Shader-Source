#if !defined(__ENTRYPOINTS_PARTICLE_FXH)
#define __ENTRYPOINTS_PARTICLE_FXH

#include "core/core_vertex_types.fxh"
#include "atmosphere/atmosphere.fxh"
#include "fx/particle_index_registers.fxh"

#define DEFAULT_DEPTH_FADE_RANGE 0.5f
#include "depth_fade.fxh"

#if defined(xenon) || (DX_VERSION == 11)

// BEGIN LARGELY UNCHANGED BUNGIE STUFF

float2 frame_texcoord(int frame_index, float2 vertex_uv, float2 scroll, float scale)
{
	float4 sprite_definition = vs_sprite_list_sprites[frame_index];
	sprite_definition.xy+= 0.5*(1.0f-scale)*sprite_definition.zw;
	return vertex_uv*sprite_definition.zw*scale + scroll*abs(sprite_definition.zw) + sprite_definition.xy;
}

float compute_variant(float input, int count, bool one_shot, bool backwards)
{
	if (count== 1)
	{
		return 0;
	}
	else
	{
		if (one_shot)
		{
			count-= 1;
		}
		float variant= count * input;
		if (backwards)
		{
			variant= count - variant;
		}
		return variant;
	}
}

float3x3 matrix3x3_rotation_from_axis_and_angle(float3 axis, float angle)
{
	float3x3 mat;
	float2 sine_cosine;
	sincos(angle, sine_cosine.x, sine_cosine.y);
	float3 one_minus_cosine_times_axis= (1.0f-sine_cosine.yyy)*axis;

	//axis= normalize(axis);	//assume normalized

	mat[0]= one_minus_cosine_times_axis*axis.xxx + sine_cosine.yxx*float3(1.0f, axis.z, -axis.y);
	mat[1]= one_minus_cosine_times_axis*axis.yyy + sine_cosine.xyx*float3(-axis.z, 1.0f, axis.x);
	mat[2]= one_minus_cosine_times_axis*axis.zzz + sine_cosine.xxy*float3(axis.y, -axis.x, 1.0f);

	return mat;
}

#ifdef xenon

float4 unknown_value= {0, 0, 0, 0};
s_particle_memexported_state read_particle_memexported_state(int index)
{
	s_particle_memexported_state STATE;

	float4 pos_sample;
	float4 vel_sample;
	float4 rot_sample;
	float4 time_sample;
	float4 anm_sample;
	float4 anm2_sample;
	float4 rnd_sample;
	float4 rnd2_sample;
	float4 axis_sample;
	float4 col_sample;
	float4 col2_sample;

#if !defined(pc)
	asm {
		vfetch pos_sample, index.x, position1
		vfetch vel_sample, index.x, position2
		vfetch rot_sample, index.x, texcoord2
		vfetch time_sample, index.x, texcoord3
		vfetch anm_sample, index.x, texcoord4
		vfetch anm2_sample, index.x, texcoord5
		vfetch rnd_sample, index.x, position3
		vfetch rnd2_sample, index.x, position4
		vfetch axis_sample, index.x, normal1
		vfetch col_sample, index.x, color
		vfetch col2_sample, index.x, color1
	};
#else
	pos_sample= unknown_value;
	vel_sample= unknown_value;
	rot_sample= unknown_value;
	time_sample= unknown_value;
	anm_sample= unknown_value;
	anm2_sample= unknown_value;
	rnd_sample= unknown_value;
	rnd2_sample= unknown_value;
	axis_sample= unknown_value;
	col_sample= unknown_value;
	col2_sample= unknown_value;
#endif // !defined(pc)

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	STATE.m_position= pos_sample.xyz;
	STATE.m_velocity= vel_sample.xyz;
	STATE.m_axis= axis_sample.xyz;
	STATE.m_birth_time= time_sample.x;
	STATE.m_age= time_sample.z;
	STATE.m_inverse_lifespan= time_sample.y;
	STATE.m_physical_rotation= rot_sample.x;
	STATE.m_manual_rotation= rot_sample.y;
	STATE.m_animated_frame= rot_sample.z;
	STATE.m_manual_frame= rot_sample.w;
	STATE.m_rotational_velocity= anm_sample.x;
	STATE.m_frame_velocity= anm_sample.y;
	STATE.m_color= col_sample;
	STATE.m_initial_color= col2_sample;
	STATE.m_random= rnd_sample;
	STATE.m_random2= rnd2_sample;
	STATE.m_size= pos_sample.w;
	STATE.m_aspect= vel_sample.w;
	STATE.m_intensity= time_sample.w;
	STATE.m_black_point= anm2_sample.x;
	STATE.m_white_point= anm2_sample.y;
	STATE.m_palette_v= anm2_sample.z;
	STATE.m_game_simulation_a= anm_sample.z;
	STATE.m_game_simulation_b= anm_sample.w;

	return STATE;
}

#elif DX_VERSION == 11

#include "fx/particle_pack.fxh"

s_particle_memexported_state read_particle_memexported_state(in int index)
{
	return unpack_particle_state(vs_particle_state_buffer[index]);
}

#endif

#define _particle_billboard_type_screen_facing			0
#define _particle_billboard_type_camera_facing			1
#define _particle_billboard_type_screen_parallel		2
#define _particle_billboard_type_screen_perpendicular	3
#define _particle_billboard_type_screen_vertical		4
#define _particle_billboard_type_screen_horizontal		5
#define _particle_billboard_type_local_vertical			6
#define _particle_billboard_type_local_horizontal		7
#define _particle_billboard_type_world					8
#define _particle_billboard_type_velocity_horizontal	9

// Return the billboard basic in world space.
// The z-direction needs to point towards the camera for backface culling.
float3x3 billboard_basis(float3 position, float3 velocity)
{
	float3x3 basis;
	if (vsRenderState.billboardType== _particle_billboard_type_screen_facing)
	{
		// basis is the x- and y- screen vectors
		basis[0]= vs_view_camera_right;
		basis[1]= vs_view_camera_up;
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_camera_facing)
	{
		// basis which doesn't change with camera rotation
		float3 eye= normalize(position - vs_view_camera_position);
		float3 perpendicular= (abs(eye.z) < 0.99f) ? float3(0, 0, 1) : float3(1, 0, 0);
		basis[0]= safe_normalize(cross(eye, perpendicular));
		basis[1]= safe_normalize(cross(basis[0], eye));
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_screen_parallel)
	{
		// basis contains velocity vector, and attempts to face screen
		basis[0]= normalize(velocity);
		basis[1]= safe_normalize(cross(basis[0], position - vs_view_camera_position));
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_screen_perpendicular)
	{
		// basis is perpendicular to the particle velocity
		float3 motion= normalize(velocity);
		float3 perpendicular= (abs(motion.z) < 0.99f) ? float3(0, 0, 1) : float3(1, 0, 0);
		basis[0]= safe_normalize(cross(motion, perpendicular));
		basis[1]= cross(motion, basis[0]);	// already normalized
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_screen_vertical)
	{
		// basis has local-space vertical vector, and a perpendicular vector in screen space
		basis[1]= float3(0.0f, 0.0f, 1.0f);
		basis[0]= safe_normalize(cross(basis[1], vs_view_camera_position - position));	// could be simplified
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_screen_horizontal)
	{
		// basis is the local-space horizonal plane xy-basis
		basis[0]= float3(1.0f, 0.0f, 0.0f);
		basis[1]= float3(0.0f, 1.0f, 0.0f);
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_local_vertical)
	{
		// basis has local-space vertical vector, and a perpendicular vector in screen space
		basis[0]= float3(vs_emitter_to_world_matrix[0][2], vs_emitter_to_world_matrix[1][2], vs_emitter_to_world_matrix[2][2]);
		basis[1]= safe_normalize(cross(basis[0], position - vs_view_camera_position));	// could be simplified
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_local_horizontal)
	{
		// basis is the local-space horizonal plane xy-basis
		basis[1]= float3(vs_emitter_to_world_matrix[0][0], vs_emitter_to_world_matrix[1][0], vs_emitter_to_world_matrix[2][0]);
		basis[0]= float3(vs_emitter_to_world_matrix[0][1], vs_emitter_to_world_matrix[1][1], vs_emitter_to_world_matrix[2][1]) * -1; // hate this crap
	}
	else if (vsRenderState.billboardType== _particle_billboard_type_velocity_horizontal)
	{
		// basis contains velocity vector, and attempts to sit in the horizontal plane
		basis[0]= normalize(velocity);
		float3 perpendicular= (abs(basis[0].x) < 0.99f) ? float3(1, 0, 0) : float3(0, 0, 1);
		basis[1]= safe_normalize(cross(perpendicular, basis[0]));
	}
	else // if (vsRenderState.billboardType== _particle_billboard_type_world)
	{
		// basis is world space
		basis[0]= float3(1.0f, 0.0f, 0.0f);
		basis[1]= float3(0.0f, 1.0f, 0.0f);
	}
	basis[2]= cross(basis[0], basis[1]);
	return basis;
}

s_particle_interpolated_values KillParticle()
{
	s_particle_interpolated_values outValues;
	outValues.position.xyzw = vs_hiddenFromCompilerNaN;
	outValues.texcoord_sprite0 = float2(0.0f, 0.0f);
	outValues.texcoord_billboard = float2(0.0f, 0.0f);
	outValues.black_point = 0.0f;
	outValues.white_point = 0.0f;
	outValues.palette = 0.0f;
	outValues.color= float4(0.0f, 0.0f, 0.0f, 0.0f);
	outValues.colorAdd = float3(0.0f, 0.0f, 0.0f);
#if defined(PASS_TANGENT_FRAME)
	outValues.tangent = float3(0.0f, 0.0f, 0.0f);
	outValues.binormal = float3(0.0f, 0.0f, 0.0f);
#endif // defined(PASS_TANGENT_FRAME)
	outValues.normal= float3(0.0f, 0.0f, 0.0f);
	outValues.depth= 0.0f;
	outValues.custom_value = float2(0.0f, 0.0f);
#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	outValues.custom_value2 = float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif // defined(PARTICLE_EXTRA_INTERPOLATOR)
#if defined(FRESNEL_ENABLED)
	outValues.viewDir = float3(0,0,0);
#endif // defined(FRESNEL_ENABLED)
	return outValues;
}

s_particle_interpolated_values ProcessVertexAndState(
	s_particle_memexported_state STATE,
	float3 vertex_pos,
	float2 vertex_uv,
	float3 vertex_normal,
	float3x3 vertex_orientation)
{
	s_particle_interpolated_values out_values;

	// Transform from local space to world space
	float3 position= mul(vs_emitter_to_world_matrix, float4(STATE.m_position, 1.0f));
	position -= normalize(vs_view_camera_position - position) * vsRenderState.curvature_cameraOffset.y;
	float3 velocity= mul((float3x3)vs_emitter_to_world_matrix, STATE.m_velocity);

	// Compute the vertex position within the plane of the sprite
	float3 planar_pos= vertex_pos;
	float particle_scale= STATE.m_size;
	float3 relative_velocity= velocity;
	float aspect= STATE.m_aspect;

	if (TEST_BIT(vsRenderState.appearanceFlags, eAF_velocityRelativeToCamera))
	{
		relative_velocity -= vs_cameraVelocity;
	}

	planar_pos.x*= aspect;

	// Transform from sprite plane to world space.
	float3x3 plane_basis= mul(vertex_orientation, billboard_basis(position, relative_velocity));	// in world space
	position.xyz += mul(planar_pos, plane_basis) * particle_scale;

	// Transform from world space to clip space.
	out_values.position= mul(float4(position, 1.0f), vs_view_view_projection_matrix);
	float3 viewDir = position.xyz - vs_view_camera_position;
	float depth= dot(vs_view_camera_backward, -viewDir);
	
#if defined(FRESNEL_ENABLED)
	out_values.viewDir = normalize(viewDir);
#endif // #if defined(FRESNEL_ENABLED)
	out_values.depth= depth;
	
	float fadeDepth = depth * vsRenderState.firstPerson_fadeDepthMultiplier.y;

	// Make a world-space normal.

	float3x3 vertexBasis;
	// Start with just the plane.
	vertexBasis[0] = plane_basis[0];
	vertexBasis[1] = plane_basis[1];
	vertexBasis[2] = plane_basis[2];

#if defined(PASS_TANGENT_FRAME)
	[branch]
	if (vsRenderState.curvature_cameraOffset.x > 0.0f)
	{
		// Rotate based on where we are in the plane.
		float3 planeOffset = safe_normalize(planar_pos);

		float3 rotationAxis = mul(float2(-planeOffset.y, planeOffset.x), vertexBasis);
		float3x3 rotationMatrix = matrix3x3_rotation_from_axis_and_angle(rotationAxis, vsRenderState.curvature_cameraOffset.x * (pi / 2.0f));
		vertexBasis = mul(vertexBasis, rotationMatrix);
	}


#if defined(RENDER_DISTORTION)
	// For distortion, these are in view space; for lighting in world space.
	vertexBasis[0] = mul(float3x3(vs_view_camera_right, vs_view_camera_up, -vs_view_camera_backward), vertexBasis[0])
		* particle_scale * vs_sprite_offset_and_scale.z;
	vertexBasis[1] = mul(float3x3(vs_view_camera_right, vs_view_camera_up, -vs_view_camera_backward), vertexBasis[1])
		* particle_scale * vs_sprite_offset_and_scale.w;
#endif

	out_values.tangent = vertexBasis[0];	// corresponds to direction of increasing u
	out_values.binormal = vertexBasis[1];	// corresponds to direction of increasing v

#else // defined(PASS_TANGENT_FRAME)
	[branch]
	if (vsRenderState.curvature_cameraOffset.x > 0.0f)
	{
		// Rotate based on where we are in the plane.
		float3 planeOffset = safe_normalize(planar_pos);
		vertexBasis[2] += tan(vsRenderState.curvature_cameraOffset.x * (pi / 2.0f)) * mul(planeOffset, vertexBasis);

		// This winds up being non-unit-length
		vertexBasis[2] = normalize(vertexBasis[2]);
		out_values.normal = mul(vertex_normal, vertexBasis);
	}
#endif // defined(PASS_TANGENT_FRAME)

	out_values.normal= mul(vertex_normal, plane_basis);

	// Compute vertex texcoord
	if (TEST_BIT(vsRenderState.appearanceFlags, eAF_randomlyFlipU) && TEST_BIT(256 * STATE.m_random.x,0))
	{
		vertex_uv.x = 1 - vertex_uv.x;
	}
	if (TEST_BIT(vsRenderState.appearanceFlags, eAF_randomlyFlipV) && TEST_BIT(256 * STATE.m_random.y,0))
	{
		vertex_uv.y = 1 - vertex_uv.y;
	}

	out_values.texcoord_billboard= vertex_uv;
	float2 uv_scroll= float2(0, 0);
	float uv_scale0= 1.0f;


	[branch]
	if (NewSchoolFrameIndex)
	{
		// we're just gonna use a w-coordinate into the tex array. Eventually we should be able to reclaim this interpolator.
		out_values.texcoord_sprite0 = float2(STATE.m_animated_frame + STATE.m_manual_frame, 0.0f);
	}
	else
	{
		float frame= compute_variant(STATE.m_animated_frame + STATE.m_manual_frame, vs_sprite_list_count_and_max.x,
			false,//TEST_BIT(g_render_state.m_animation_flags,_frame_animation_one_shot_bit),
			false);//TEST_BIT(g_render_state.m_animation_flags,_can_animate_backwards_bit) && TEST_BIT(256*STATE.m_random.z,0));
		int frame_index0= floor(frame%vs_sprite_list_count_and_max.x);
		out_values.texcoord_sprite0= frame_texcoord(frame_index0, vertex_uv, uv_scroll, uv_scale0);
	}

	// Compute particle color
	out_values.color.xyz= STATE.m_color.xyz * STATE.m_initial_color.xyz * STATE.m_intensity * exp2(STATE.m_initial_color.w);

	// Compute particle alpha
	out_values.color.a= STATE.m_color.w;
	if (TEST_BIT(vsRenderState.appearanceFlags, eAF_intensityAffectsAlpha))
	{
		out_values.color.w *= STATE.m_intensity;
	}
	if (!vsRenderState.firstPerson_fadeDepthMultiplier.x)
	{
		out_values.color.w *= saturate((fadeDepth - vsRenderState.fade.nearCutoff) / vsRenderState.fade.nearRange);
	}
	out_values.color.w *= saturate((vsRenderState.fade.farCutoff - fadeDepth) / vsRenderState.fade.farRange);

#if !defined(RENDER_DISTORTION)
	if (LightingPerParticle)
	{
		float3 lightValue = vsLightingAmbient / pi;
		float lightIntensity = length(lightValue);

		// adjust the alpha for very bright or very dark
		if (lightIntensity < 0.5)
		{
			out_values.color.w *= lerp(1.0, (lightIntensity + .5) / (1.5 * lightIntensity + .25), lighting_dim_alpha_increase * lighting_per_particle_strength);
		}
		else if (lightIntensity > 1.0)
		{
			out_values.color.w *= lerp(1.0, (lightIntensity + 9) / (10 * lightIntensity), lighting_bright_alpha_decrease * lighting_per_particle_strength);
		}
		
		lightValue = lerp(lightValue, lightValue / max(max(lightValue.r, lightValue.g), max(lightValue.b, 1)), lighting_bright_intensity_decrease);
		out_values.color.xyz *= lerp(float3(1.0, 1.0, 1.0), lightValue, lighting_per_particle_strength);
	}
#endif // !defined(RENDER_DISTORTION)
	if (TEST_BIT(vsRenderState.appearanceFlags, eAF_fadeNearEdge))
	{
		// Fade to transparent when billboard is edge-on ... but independent of camera orientation
		float3 cameraToVertex = normalize(position.xyz - vs_view_camera_position);
		float billboardAngle = (pi / 2.0f) - acos(abs(dot(cameraToVertex, out_values.normal)));
		out_values.color.w *= saturate(vsRenderState.fade.edgeRange * (billboardAngle - vsRenderState.fade.edgeCutoff));
	}

	out_values.black_point= saturate(STATE.m_black_point);
	out_values.white_point= saturate(STATE.m_white_point);
#if DX_VERSION == 11
	// Prevent numerical instability when black point and white point are the same
	out_values.white_point= max(out_values.white_point, out_values.black_point + 0.00001);
#endif	
	out_values.palette= (saturate(STATE.m_palette_v) != STATE.m_palette_v) ? frac(STATE.m_palette_v) : STATE.m_palette_v;
	out_values.custom_value = float2(0.0f, 0.0f);
	
	// fog stuff
	{
		float3 fogInscatter;
		float extinction;
		float placeholder;
		ComputeAtmosphericScattering(
			vs_atmosphere_fog_table,
			position - vs_view_camera_position,
			position,
			fogInscatter,
			extinction,
			placeholder,
			false,
			false);
		out_values.colorAdd = fogInscatter * vs_material_blend_constant.y * vs_bungie_exposure.x;
		out_values.color.rgb *= extinction;
	}

#if defined(CUSTOM_VERTEX_PROCESSING)
	CustomVertexProcessing(STATE, position, out_values);
#endif // defined(CUSTOM_VERTEX_PROCESSING)

#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	FillExtraInterpolator(STATE, out_values);
#endif // !defined(PARTICLE_EXTRA_INTERPOLATOR)

	return out_values;
}

#if DX_VERSION == 9
s_particle_interpolated_values do_some_bungie_stuff_model(in s_particle_vertex input)
#elif DX_VERSION == 11
s_particle_interpolated_values do_some_bungie_stuff_model(in s_particle_vertex input)
#endif
{
	s_particle_interpolated_values out_values;
	// This would be used for killing verts by setting oPts.z!=0 .
	//asm {
	//	config VsExportMode=kill
	//};

	// Break the input index into a instance index and a vert index within the primitive.
	int instance_index = round((input.index + 0.5f)/ vsRenderState.vertexCount - 0.5f);	// This calculation is approximate (hence the 'round')
	int vertex_index = input.index - instance_index * vsRenderState.vertexCount; // This calculation is exact

	s_particle_memexported_state STATE= read_particle_memexported_state(instance_index);
	//float pre_evaluated_scalar[_index_max]= preevaluate_particle_functions(STATE);

	// Kill timed-out particles...
	// Should be using oPts.z kill, but that's hard to do in hlsl.
	// XDS says equivalent to set position to NaN?
	if (STATE.m_age >= 1.0f || STATE.m_color.w== 0.0f)	// early out if particle is dead or transparent.
	{
		out_values = KillParticle();
	}
	else
	{
		// Precompute rotation value
		float rotation= STATE.m_physical_rotation + STATE.m_manual_rotation;

		// Compute vertex inputs for a mesh particle
		float4x2 shift = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}, };
		float3 vertex_pos;
		float2 vertex_uv;
		float3 vertex_normal;
		float3x3 vertex_orientation;

		float variant = compute_variant(STATE.m_animated_frame + STATE.m_manual_frame, vsMeshVariantList.m_meshVariantCount,
			false,//TEST_BIT(g_render_state.m_animation_flags,_frame_animation_one_shot_bit),
			false);//TEST_BIT(g_render_state.m_animation_flags,_can_animate_backwards_bit) && TEST_BIT(256*STATE.m_random.z,0));
		int variant_index0 = floor(variant % vsMeshVariantList.m_meshVariantCount);
		vertex_index = min(vertex_index,
			vsMeshVariantList.m_meshVariants[variant_index0].m_meshVariantEndIndex - vsMeshVariantList.m_meshVariants[variant_index0].m_meshVariantStartIndex);
		vertex_index += vsMeshVariantList.m_meshVariants[variant_index0].m_meshVariantStartIndex;

		float4 pos_sample;
		float4 uv_sample;
		float4 normal_sample;
#ifdef xenon		
		asm {
			vfetch pos_sample, vertex_index, position
			vfetch uv_sample, vertex_index, texcoord
			vfetch normal_sample, vertex_index, normal
		};
#elif DX_VERSION == 11
		uint offset = vertex_index * 20;
		
		pos_sample = UnpackUShort4N(mesh_vertices.Load2(offset));
		uv_sample = float4(UnpackUShort2N(mesh_vertices.Load(offset + 8)), 0, 0);
		normal_sample = UnpackHalf4(mesh_vertices.Load2(offset + 12));
#endif		
		
		vertex_pos= pos_sample.xyz * vs_mesh_position_compression_scale.xyz + vs_mesh_position_compression_offset.xyz;
		vertex_uv= uv_sample.xy * vs_mesh_uv_compression_scale_offset.xy + vs_mesh_uv_compression_scale_offset.zw;
		vertex_normal= normal_sample.xyz;
		vertex_orientation= matrix3x3_rotation_from_axis_and_angle(STATE.m_axis, 2 * pi * rotation);

		out_values = ProcessVertexAndState(STATE, vertex_pos, vertex_uv, vertex_normal, vertex_orientation);
	}

	return out_values;
}

s_particle_interpolated_values do_some_bungie_stuff_billboard(in s_particle_vertex input)
{
	s_particle_interpolated_values out_values;
	// This would be used for killing verts by setting oPts.z!=0 .
	//asm {
	//	config VsExportMode=kill
	//};

	// Break the input index into a instance index and a vert index within the primitive.
	int instance_index = round((input.index + 0.5f)/ vsRenderState.vertexCount - 0.5f);	// This calculation is approximate (hence the 'round')
	int vertex_index = input.index - instance_index * vsRenderState.vertexCount; // This calculation is exact

	s_particle_memexported_state STATE= read_particle_memexported_state(instance_index);
	//float pre_evaluated_scalar[_index_max]= preevaluate_particle_functions(STATE);

	// Kill timed-out particles...
	// Should be using oPts.z kill, but that's hard to do in hlsl.
	// XDS says equivalent to set position to NaN?
	if (STATE.m_age >= 1.0f || STATE.m_color.w== 0.0f)	// early out if particle is dead or transparent.
	{
		out_values = KillParticle();
	}
	else
	{
		// Precompute rotation value
		float rotation= STATE.m_physical_rotation + STATE.m_manual_rotation;
		
		CustomVerts customVerts = vsRenderState.customVerts[STATE.m_black_point * CUSTOM_VERT_SET_COUNT];

		// Compute vertex inputs which depend whether we are a billboard or a mesh particle
		float4x2 shift = {	{customVerts.customVertex0.x, customVerts.customVertex0.y},
							{customVerts.customVertex0.z, customVerts.customVertex0.w},
							{customVerts.customVertex1.x, customVerts.customVertex1.y},
							{customVerts.customVertex1.z, customVerts.customVertex1.w}, };
		float3 vertex_pos;
		float2 vertex_uv;
		float3 vertex_normal;
		float3x3 vertex_orientation;

		vertex_pos= float3(shift[vertex_index] * vs_sprite_offset_and_scale.zw + vs_sprite_offset_and_scale.xy, 0.0f);
		vertex_uv= float2(shift[vertex_index].x, 1.0f - shift[vertex_index].y); // artists complained that bitmaps came in upside down
		vertex_normal= float3(0.0f, 0.0f, 1.0f);
		float rotsin, rotcos;
		sincos((2 * pi) * rotation, rotsin, rotcos);
		vertex_orientation= float3x3(float3(rotcos, rotsin, 0.0f), float3(-rotsin, rotcos, 0.0f), float3(0.0f, 0.0f, 1.0f));

		out_values = ProcessVertexAndState(STATE, vertex_pos, vertex_uv, vertex_normal, vertex_orientation);

		// extra kill test for billboards only... not strictly correct since other verts in the quad might be alive, but that just kills
		// the whole quad, which isn't the end of the world
		if (out_values.color.w == 0.0f &&
			!TEST_BIT(vsRenderState.appearanceFlags, eAF_neverKillVertices)) // can be bad artifacts if verts are at different depths
		{
			out_values.position.xyzw = vs_hiddenFromCompilerNaN.xxxx;
		}
	}

	if (ConstantScreenSize)
	{
		out_values.position.w = 1.0f;
	}

	return out_values;
}

// END BUNGIE STUFF

float2 ComputeSphereWarp(float2 texcoordBillboard)
{
	[branch]
	if (psSphereWarpEnabled)
	{
		// sphere warp sprite, based on billboard
		float2 delta = texcoordBillboard * 2 - 1; /// [-1, 1] across sprite

		float delta2 = dot(delta.xy, delta.xy);
		float delta4 = delta2 * delta2;

		// we don't need to calculate delta, since it cancels itself out.  save the sqrt, save the world!
		float deltaOffset = delta4 * SphereWarpStrength; // decent approximation of a sphere

		float2 offset = delta.xy * deltaOffset;

		return offset;
	}
	else
	{
		return float2(0.0f, 0.0f);
	}
}

void default_particle_vs(
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID,
#else
	in s_particle_vertex input,
#endif
	out s_particle_interpolators_internal out_interpolators)
{
#if DX_VERSION == 11
	uint quad_index = (vertex_id ^ ((vertex_id & 2) >> 1));	

	s_particle_vertex input;
	input.index = (instance_id * 4) + quad_index + particle_index_range.x;
	input.address = 0;
#endif

	s_particle_interpolated_values particle_values= do_some_bungie_stuff_billboard(input);

	particle_values.color= vs_apply_exposure(particle_values.color);

	out_interpolators= write_particle_interpolators(particle_values);
}

void default_particle_model_vs(
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID,
#else
	in s_particle_model_vertex model_input,
#endif
	out s_particle_interpolators_internal out_interpolators)
{
#if DX_VERSION == 9
	s_particle_interpolated_values particle_values= do_some_bungie_stuff_model(input);
#elif DX_VERSION == 11
	s_particle_vertex input;
	input.index = (instance_id * particle_index_range.y) + vertex_id + particle_index_range.x;
	input.address = 0;
	s_particle_interpolated_values particle_values= do_some_bungie_stuff_model(input);
#endif


	particle_values.color= vs_apply_exposure(particle_values.color);

	out_interpolators= write_particle_interpolators(particle_values);
}

void default_default_ps(
	in s_particle_interpolators_internal in_interpolators,
	SCREEN_POSITION_INPUT(fragment_position),
	out float4 out_color: SV_Target0)
{
	s_particle_interpolated_values particle_values= read_particle_interpolators(in_interpolators);

	// adjust for any tiling offsets early
	fragment_position.xy += ps_tiling_vpos_offset.xy;

	float depthFade = 1.0f;

	[branch]
	if (psDepthFadeEnabled)
	{
		depthFade = ComputeDepthFade(fragment_position * psDepthConstants.z, particle_values.depth);
		if (DepthFadeAsVCoord)
		{
			particle_values.texcoord_billboard.y = depthFade;
			particle_values.texcoord_sprite0.y = depthFade;
			depthFade = 1.0f;
		}
	}

#if defined(RENDER_DISTORTION)

	float2 displacement = PixelComputeDisplacement(particle_values);

	displacement.y = -displacement.y;
	displacement *= psDistortionScreenConstants.z * particle_values.color.a * depthFade;

	float2x2 billboardBasis = float2x2(particle_values.tangent.xy, particle_values.binormal.xy);
	float2 frameDisplacement = mul(billboardBasis, displacement) / particle_values.depth;

	// At this point, displacement is in units of frame widths/heights.  I don't think pixel kill gains anything here.
	// We now require pixel kill for correctness, because we don't use depth test.
	clip(dot(frameDisplacement, frameDisplacement) == 0.0f ? -1 : 1);

	// Now use full positive range of render target [0.0,32.0)
	float2 distortion = DistortionStrength * frameDisplacement;

	if (DistortionExpensiveDepthTest)
	{
		static float fudgeScale = 1.0f;
		clip(ComputeDepthFade(fragment_position + distortion * fudgeScale / 64.0f, particle_values.depth) == 0 ? -1 : 1);
	}

	out_color = float4(distortion * psDistortionScreenConstants, 1.0f, 1.0f);

#else // defined(RENDER_DISTORTION)

	float2 sphereWarp = ComputeSphereWarp(particle_values.texcoord_billboard);

	out_color= pixel_compute_color(particle_values, sphereWarp, depthFade);

	[branch]
	if (LightingSmooth)
	{
#if defined(MODIFY_NORMAL)
		particle_values.normal = ModifyNormal(particle_values);
#endif // defined(MODIFY_NORMAL)
#if defined(CUSTOM_LIGHTING_MODEL)
		out_color.rgb = CustomLighting(out_color.rgb, particle_values);
#else
		float cosine = dot(particle_values.normal.xyz, psLightingBrightDirection.xyz);
		float biased = saturate(cosine * LightingContrastScale + LightingContrastOffset);
		float blend = pow(biased, 3);
		float3 lightColor = lerp(psLightingDarkColor.rgb, psLightingBrightColor.rgb, blend);
		out_color.rgb *= lerp(float3(1.0, 1.0, 1.0), lightColor / pi, LightingStrength);
#endif
	}

	if (IS_BLEND_MODE_PS(additive))
	{
		out_color.rgb *= depthFade;
	}
	else
	{
		out_color.a *= depthFade;
	}

	[branch]
	if (psBlackOrWhitePointEnabled)
	{
		out_color.a = ApplyBlackPointAndWhitePoint(particle_values.black_point, particle_values.white_point, out_color.a);
	}

	out_color= ps_apply_exposure(
		out_color,
		particle_values.color,
		particle_values.colorAdd,
		psTintFactor);

#if DX_VERSION == 11
	// Saturation occurs on 360 (and D3D9 in general?) before alpha blending, at least for fixed point surfaces.
	// Some particle effects rely on this to look right so for now I'm saturating the output here - so far this is
	// the only thing I've found that needs it but possible we might need to do this for all pixel shader outputs
	// (but obviously we probably don't want to saturate if the destination surface is not fixed point).
	out_color = saturate(out_color);
#endif
		
#endif // defined(RENDER_DISTORTION)
}

#else // defined(xenon)

float4 default_particle_vs() : SV_Position0
{
	return float4(0, 0, 0, 1);
}

float4 default_particle_model_vs() : SV_Position0
{
	return float4(0, 0, 0, 1);
}

float4 default_default_ps() : SV_Target0
{
	return float4(0, 0, 0, 0);
}

#endif // defined(xenon)

#endif 	// !defined(__ENTRYPOINTS_PARTICLE_FXH)