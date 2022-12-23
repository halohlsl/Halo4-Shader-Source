#if !defined(__NORMAL_FXH)
#define __NORMAL_FXH



// expands a noraml -1 to 1
void normal_expand(inout float3 normal){
    normal = ((normal * 2) - 1);
}

// dexpands normal from -1 - 1 to 0 - 1
void normal_deexpand(inout float3 normal) {
    normal = ((normal + 1) * 0.5);
}    

// a composite method for normal maps
float3 normal_overlay(
            float3 base_normal,
            float3 over_normal,
            float opacity ) 
{
    over_normal *= float3(1,1,0.5);      
    over_normal =  lerp(float3(0.5,0.5,0.5), over_normal, opacity);
    return  color_overlay(base_normal, over_normal);
}


float3 normal_overlay2(
            float3 a, 
            float3 b)
{
    float  l   = 1-b.z;   
    float3 w   = float3(1.0,1.0,1.0);
    float3 ovr = 2.0 * b.xyz * a.xyz;
    float3 udr = w - 2.0*((w - a.xyz) * (w - b.xyz));  
    return lerp(ovr, udr, 1);     
}



#endif 	// !defined(__CORE_TYPES_FXH)
