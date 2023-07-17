//
// File:	 srf_env_distanceFade_edgeFade_fresnel.fx
// Author:	 wesleyg
// Date:	 06/11/12
//
// Distance Fade Surface Shader - Cheap constant shader that fades as it is approached and can bloom out - can be used as visibility blocker for culling.
//									This version includes an edge fade gradient that allows you to fade of the edges of the card and fresnel base alpha falloff
//									for large fade cards that would otherwise be visible extending off into the distance if you are close to them.
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

#define EDGE_FADE
#define FRESNEL_FADE

#include "srf_env_distanceFade.fx"