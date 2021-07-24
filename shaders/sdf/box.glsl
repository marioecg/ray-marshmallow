float box(vec3 p, vec3 s) {
  p = abs(p) - s;
  
  return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

#pragma glslify: export(box)