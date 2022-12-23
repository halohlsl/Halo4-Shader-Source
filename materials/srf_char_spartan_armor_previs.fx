//
// File:	 xsrf_spartan_armor_previs.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Spartan Armor shader for apply custom lookup to change colors
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
/*
special case shader for MP Spartan Armor sets. The shader needs to take a packed control map and apply the Primary and Secondary color sets based on a painted mask.

Two core maps as input for each armor component
(perhaps a detail normal for hi-frequency noise).

Normal - standard normal map

Control map
R - Color/Diffuse Intensity
G - Spec
B - Gloss
A - Color Mask

*/

#define ARMOR_PREVIS
#include "srf_char_spartan_armor.fx"