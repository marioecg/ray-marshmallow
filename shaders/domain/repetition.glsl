float opRep(in vec3 p, in vec3 c, in float sdf) {
    vec3 q = mod(p + 0.5 * c, c) - 0.5 * c;
    
    return sdf(q);
}

#pragma glslify: export(opRep)