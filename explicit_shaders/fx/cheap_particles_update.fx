#include "fx/cheap_particle_core.fxh"

#define DROP_TEXTURE_SIZE 128
#define SPLASH_TEXTURE_SIZE 512

#define PARTICLE_TEXTURE_WIDTH 128
#define PARTICLE_TEXTURE_HEIGHT 64

#if DX_VERSION == 11
	#define turbulenceSampler cs_turbulenceSampler
#else
	#define turbulenceSampler vs_turbulenceSampler
#endif

float3 VSDecodeWorldspaceNormalSigned(float2 encodedNormal)
{
#if defined(xenon) || (DX_VERSION == 11)
#if DX_VERSION == 11
	encodedNormal = (encodedNormal * 2.0) - 1.0;
#endif
	float2 expanded = encodedNormal;
	float f = dot(expanded, expanded);
	float2 g = float2(-0.25 * 4.0, -0.5) * 4.0 * f + float2(4.0, 1.0);
	float3 normal = float3(expanded * sqrt(g.x), g.y);
	return mul(vs_worldspace_normal_axis, normal);
#else
	return float3(0, 0, 1);
#endif
}

void UpdateParticle(in int index)
{
	float particleIndex = index;
	
	float4 positionAndAge = FetchPositionAndAge(particleIndex);

	if (abs(positionAndAge.w) < 1.0f)
	{
		float4 velocityAndDeltaAge = FetchVelocityAndDeltaAge(particleIndex);
		float deltaAge = velocityAndDeltaAge.w;

		float4 particleParameters = FetchParticleParameters(particleIndex);
		float particleType = particleParameters.x;
		float sizeScale = 1.0f;

		float4 physics = GetTypeData(particleType, TYPE_DATA_PHYSICS);
		float drag = physics.x;
		float gravity = -physics.y;
		float turbulence = physics.z;
		float turbulenceType = physics.w;
		float4 collision = GetTypeData(particleType, TYPE_DATA_COLLISION);
		float collisionRange = collision.x; // 0.1f world units
		float collisionBounce = collision.y;
		float collisionDeath = collision.z;				
		float collisionType = collision.w;

		positionAndAge.w += sign(positionAndAge.w) * deltaAge * vs_deltaTime;

		if (positionAndAge.w >= 0.0f) // 'at rest' is determined by sign of age
		{
			// not 'at rest'
#if DX_VERSION == 11			
			float turbZ = (turbulenceType * vs_arrayTextureParameters.z) + vs_arrayTextureParameters.w;
#else
			float turbZ = turbulenceType;
#endif
			float4 turbSample = turbulence * GenerateRandomInRange(particleIndex, turbZ, turbulenceSampler, vs_turbulenceTransform[(int)(4.0 * turbulenceType)], -1.0f, 1.0f);
			
			positionAndAge.xyz	+= (velocityAndDeltaAge.xyz + turbSample) * vs_deltaTime.x + float3(0, 0, gravity) * vs_deltaTime.x * vs_deltaTime.x;
			velocityAndDeltaAge.xyz	+= (float3(0, 0, gravity) - velocityAndDeltaAge.xyz * drag) * vs_deltaTime.x;		
		}
		
		{
			// check depth buffer
			float4 projectedPosition = float4(positionAndAge.xyz, 1.0f);
			projectedPosition = mul(projectedPosition, vs_view_view_projection_matrix);				
			projectedPosition.xyz /= projectedPosition.w; // [-1, 1]	
			projectedPosition.xy = projectedPosition.xy * float2(0.5f, -0.5f) + 0.5f; // [0, 1] ###ctchou $TODO can build this into a modified version of vs_view_view_projection_matrix above
			
			float2 outside = projectedPosition.xy - saturate(projectedPosition.xy); // 0,0 if the point is inside [0,1] screen bounds
			if (dot(outside, outside) == 0.0f)
			{
				float4 depthValue;
#ifdef xenon				
				asm
				{
					tfetch2D depthValue, projectedPosition.xy, vs_collisionDepthBuffer, UnnormalizedTextureCoords = false, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled, UseComputedLOD = false, UseRegisterGradients = false
				};
#else
				depthValue = cs_collisionDepthBuffer.t.SampleLevel(cs_collisionDepthBuffer.s, projectedPosition.xy, 0);
#endif
				float sceneDepth = 1.0f - depthValue.x;
				sceneDepth = 1.0f / (vs_collisionDepthConstants.x + sceneDepth * vs_collisionDepthConstants.y); // convert to real depth
				
				if (positionAndAge.w >= 0.0f)
				{
					if (abs(projectedPosition.w - sceneDepth - collisionRange) < collisionRange)
					{
						// move particle to the collision location
						float3 cameraToDrop = positionAndAge.xyz - vs_view_camera_position;
						float reprojectionScale = sceneDepth / dot(cameraToDrop, -vs_view_camera_backward);
						cameraToDrop *= reprojectionScale;
						positionAndAge.xyz = cameraToDrop + vs_view_camera_position;
										
						float3 normal;
						float4 normalSample;
#ifdef xenon						
						asm
						{
							tfetch2D normalSample, projectedPosition.xy, vs_collisionNormalBuffer, UnnormalizedTextureCoords = false, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled, UseComputedLOD = false, UseRegisterGradients = false
						};
#else
						normalSample = cs_collisionNormalBuffer.t.SampleLevel(cs_collisionNormalBuffer.s, projectedPosition.xy, 0);
#endif
						normal = VSDecodeWorldspaceNormalSigned(normalSample.xy);
					
						if (dot(normal, velocityAndDeltaAge.xyz) > 0.1f)
						{
							// particle is heading out of the ground, kill it (so it doesn't appear magically)
							positionAndAge.w = 2.0f;
						}
						else
						{				
							// collision detected
											
							// reflect particle velocity around normal to bounce
							velocityAndDeltaAge.xyz = collisionBounce * reflect(velocityAndDeltaAge.xyz, normal);
							
							// move particle forward along reflected velocity vector a bit.
							positionAndAge.xyz += velocityAndDeltaAge.xyz * vs_deltaTime.x * 0.5f;
							
							// check if 'at rest'
							if (length(velocityAndDeltaAge.xyz) < 0.2f)
							{
								positionAndAge.w = -positionAndAge.w;
							}
											
							// update type on collision
							particleParameters.x = collisionType - 128.0f;
							MemexportParticleParameters(particleIndex, particleParameters);
						}
					}
				}
				else
				{
					// at rest -- check if remaining at rest
					if (projectedPosition.w - sceneDepth < -0.03f)
					{
						// not colliding anymore!   reset at-rest state
						positionAndAge.w = -positionAndAge.w;
					}
				}
			}
		}
					
		MemexportPositionAndAge(particleIndex, positionAndAge);
		MemexportVelocityAndDeltaAge(particleIndex, velocityAndDeltaAge);
	}
}

#if defined(xenon)

void DefaultVS(in int index : INDEX)
{
	UpdateParticle(index);
}

float4 DefaultPS() : SV_Target0
{
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

#elif DX_VERSION == 11

[numthreads(CS_CHEAP_PARTICLE_UPDATE_THREADS,1,1)]
void DefaultCS(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		UpdateParticle(raw_index);
	}
}

#else

void DefaultVS(out float4 outPosition : SV_Position) { outPosition = 0.0f; }
float4 DefaultPS() : SV_Target0 { return 0.0f; }

#endif // !defined(xenon)

BEGIN_TECHNIQUE
{
	pass tiny_position
	{
#if DX_VERSION == 11
		SET_COMPUTE_SHADER(DefaultCS());
#else
		SET_VERTEX_SHADER(DefaultVS());
		SET_PIXEL_SHADER(DefaultPS());
#endif
	}
}