float opRep(in vec3 p, in vec3 c, in sdf3d primitive) {
    vec3 q = mod(p + 0.5 * c, c) - 0.5 * c;
    
    return primitive(q);
}