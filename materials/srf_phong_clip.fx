//
// File:	 srf_phong_clip.fx
// Author:	 aluedke
// Date:	 03/16/2012
//
// Surface Shader - Phong, with alpha clip
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes: Same as standard phong shader, though the alpha of the diffuse texture is
// 		  used to clip pixels below a threshold parameter.
//
#define ALPHA_CLIP

#include "srf_phong.fx"
