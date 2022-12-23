//
// File:	 srf_env_distanceFade_scroll_rgb_fresnel.fx
// Author:	 wesleyg
// Date:	 08/31/12
//
// Distance Fade Surface Shader - Cheap constant shader that fades as it is approached and can bloom out - can be used as visibility blocker for culling.
//									This version includes an edge fade gradient that allows you to fade of the edges of the card and also incorporates 
//									scrolling UV's (for scrolling sand in M40) and fresnel base alpha falloff for large fade cards that would otherwise 
//									be visible extending off into the distance if you are close to them (large sandstorm cards used in M40).
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

#define EDGE_FADE
#define SCROLL_UV
#define FRESNEL_FADE
#define USE_FULL_RGB

#include "srf_env_distanceFade.fx"