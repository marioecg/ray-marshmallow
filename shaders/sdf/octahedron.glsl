float octahedron(vec3 p, float s) {
  p = abs(p);
  
  return (p.x+p.y+p.z-s)*0.57735027;
}

#pragma glslify: export(octahedron)