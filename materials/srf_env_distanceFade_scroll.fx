//
// File:	 srf_env_distanceFade_scroll.fx
// Author:	 wesleyg
// Date:	 06/11/12
//
// Distance Fade Surface Shader - Cheap constant shader that fades as it is approached and can bloom out - can be used as visibility blocker for culling.
//									This version includes an edge fade gradient that allows you to fade of the edges of the card and also incorporates 
//									scrolling UV's (for scrolling sand in M40).
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

#define EDGE_FADE
#define SCROLL_UV

#include "srf_env_distanceFade.fx"