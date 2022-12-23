//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Wade custom layered shader, vertex blended
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#define VERTEX_BLEND
#define OCCLUSION_MAP
#define BLENDED_LAYER_COUNT 2
#define SPECULAR_LAYER_COUNT 1
#define DISABLE_NORMAL_DETAIL_FADE

#include "srf_layered_wade.fx"
