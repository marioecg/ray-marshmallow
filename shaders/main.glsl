precision highp float;

// Setup is based on Martijn Steinrucken aka The Art of Code
// https://www.shadertoy.com/view/WtGXDD

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.001

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uMouse;
uniform samplerCube tCube;

varying vec2 vUv;

mat2 rotation2d(float a) {
  float s = sin(a), c = cos(a);
  return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
  p = abs(p) - s;
  
  return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float getDist(vec3 p) {
  float d = sdBox(p, vec3(1));
    
  return d;
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
  vec2 e = vec2(0.001, 0.000);
  
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

  vec3 ro = vec3(0, 3, -4);
  ro.yz *= rotation2d(-m.y * 3.14 + 1.0);
  ro.xz *= rotation2d(-m.x * 6.2831);
  
  vec3 rd = getRayDir(uv, ro, vec3(0, 0, 0), 1.0);
  vec3 col = textureCube(tCube, rd).rgb;
  
  float d = raymarch(ro, rd, 1.0); // ray march outside of object

  float IOR = 1.45; // index of refraction
  
  if (d < MAX_DIST) {
    vec3 p = ro + rd * d; // 3D position when we hit
    vec3 n = getNormal(p); // Normal of surface or orientation
    
    vec3 reflectionDir = reflect(rd, n);
    // ray direction when entering the surface
    vec3 rdIn = refract(rd, n, 1.0 / IOR); // when going from a less dense medium to a more dense medium use the inverse of the IOR

    // ray march inside of the object
    // it has to start where we hit the surface at point P
    // and go in the direction of the refraction
    vec3 pEnter = p - n * SURF_DIST * 3.0; // we need to move P down a little bit because we're marching into the object
    float dIn = raymarch(pEnter, rdIn, -1.0); 

    vec3 pExit = pEnter + rdIn * dIn; // 3D position of exit point
    vec3 nExit = -getNormal(pExit); // Normal of exit and it needs to be flipped

    vec3 rdOut = refract(rdIn, nExit, IOR); // take the inverse since we are going from more dense to a lighter medium

    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);

    vec3 reflTex = textureCube(tCube, rdOut).rgb;
    col = vec3(reflTex);
  }
  
  col = pow(col, vec3(0.4545));	// gamma correction
  
  gl_FragColor = vec4(col, 1.0);
}