precision highp float;

// Setup is based on Martijn Steinrucken aka The Art of Code
// https://www.shadertoy.com/view/WtGXDD

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.001
#define PI 3.1415926535897932384626433832795
#define TWO_PI 6.2831853071795864769252867665590

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uMouse;
uniform samplerCube tCube;

varying vec2 vUv;

#pragma glslify: box = require(./sdf/box.glsl)
#pragma glslify: sphere = require(./sdf/sphere.glsl)
#pragma glslify: octahedron = require(./sdf/octahedron.glsl)
#pragma glslify: rotation2d = require(glsl-rotate/rotation-2d)
#pragma glslify: map = require(glsl-map)

float getDist(vec3 p) {
  float bx = box(p, vec3(5, 5, 0.5));

  p.xz *= rotation2d(uTime);;
  float size = map(cos(uTime * 2.0), -1.0, 1.0, 5.0, 6.5);
  float oct = octahedron(p, size);
    
  return oct;
}

float raymarch(vec3 ro, vec3 rd, float side) {
  float dO = 0.0;
  
  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dO;
    float dS = getDist(p) * side; // we need to invert the sign of the distance when going inside the object
    dO += dS;
    if(dO > MAX_DIST || abs(dS) < SURF_DIST) break;
  }
    
  return dO;
}

vec3 getNormal(vec3 p) {
  float d = getDist(p);
  vec2 e = vec2(0.1, 0.000);
  
  vec3 n = d - vec3(
    getDist(p - e.xyy),
    getDist(p - e.yxy),
    getDist(p - e.yyx)
  );
  
  return normalize(n);
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z) {
  vec3 f = normalize(l - p),
       r = normalize(cross(vec3(0, 1, 0), f)),
       u = cross(f, r),
       c = f * z,
       i = c + uv.x * r + uv.y * u,
       d = normalize(i);

  return d;
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5 * uResolution.xy) / uResolution.y;
  vec2 m = uMouse.xy / uResolution.xy;

  float roX = cos(uTime) * 10.0;
  float roY = sin(uTime) * 10.0;
  vec3 ro = vec3(10.0, 6.0, 1.0);
  ro.yz *= rotation2d(-m.y * 3.14 + 1.0);
  ro.xz *= rotation2d(-m.x * 6.2831);

  ro.xz *= rotation2d(uTime);
  // uv *= rotation2d(uTime);
  vec3 rd = getRayDir(uv, ro, vec3(0, 0, 0), 0.5);
  vec3 col = textureCube(tCube, rd).rgb;
  
  float d = raymarch(ro, rd, 1.0); // ray march outside of object

  float IOR = 1.45; // index of refraction
  
  if (d < MAX_DIST) {
    vec3 p = ro + rd * d; // 3D position when we hit
    vec3 n = getNormal(p); // Normal of surface or orientation
    
    vec3 reflectionDir = reflect(rd, n);
    // ray direction when entering the surface
    vec3 reflOutside = textureCube(tCube, reflectionDir).rgb;
    vec3 rdIn = refract(rd, n, 1.0 / IOR); // when going from a less dense medium to a more dense medium use the inverse of the IOR

    // ray march inside of the object
    // it has to start where we hit the surface at point P
    // and go in the direction of the refraction
    vec3 pEnter = p - n * SURF_DIST * 3.0; // we need to move P down a little bit because we're marching into the object
    float dIn = raymarch(pEnter, rdIn, -1.0); 

    vec3 pExit = pEnter + rdIn * dIn; // 3D position of exit point
    vec3 nExit = -getNormal(pExit); // Normal of exit and it needs to be flipped

    vec3 reflTex = vec3(0);

    vec3 rdOut = vec3(0);

    float abb = 0.01;

    // red
    rdOut = refract(rdIn, nExit, IOR - abb); // take the inverse since we are going from more dense to a lighter medium
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.r = textureCube(tCube, rdOut).r;

    // green
    rdOut = refract(rdIn, nExit, IOR); // take the inverse since we are going from more dense to a lighter medium
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.g = textureCube(tCube, rdOut).g;

    // blue
    rdOut = refract(rdIn, nExit, IOR + abb); // take the inverse since we are going from more dense to a lighter medium
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.b = textureCube(tCube, rdOut).b;

    float dens = 0.05;
    float optDist = exp(-dIn * dens); // optical density or distance

    reflTex *= optDist;

    float fresnel = pow(1.0 + dot(rd, n), 5.0);
    
    col = mix(reflTex, reflOutside, fresnel);
  }
  
  col = pow(col, vec3(0.4545));	// gamma correction
  
  gl_FragColor = vec4(col, 1.0);
}