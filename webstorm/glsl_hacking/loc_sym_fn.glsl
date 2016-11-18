#define GRID_SPACING vec2(1.0)
#define DC_SATUR 0.7
#define DC_GRID_STR 0.1
#define DC_MAG_STR 0.2
#define DC_LINE_PWR 5.0

#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable
#define M_PI 3.1415926535897932384626433832795
#define M_SQRT7 2.6457513111

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hypot (vec2 z) {
  float t;
  float x = abs(z.x);
  float y = abs(z.y);
  t = min(x, y);
  x = max(x, y);
  t = t / x;
  return (z.x == 0.0 && z.y == 0.0) ? 0.0 : x * sqrt(1.0 + t * t);
}

vec4 domainColoring (vec2 z, vec2 gridSpacing, float saturation, float gridStrength, float magStrength, float linePower) {
  float carg = atan(z.y, z.x);
  float cmod = hypot(z);

  float rebrt = (fract(z.x / gridSpacing.x) - 0.5) * 2.0;
  rebrt *= rebrt;

  float imbrt = (fract(z.y / gridSpacing.y) - 0.5) * 2.0;
  imbrt *= imbrt;

  float grid = 1.0 - (1.0 - rebrt) * (1.0 - imbrt);
  grid = pow(abs(grid), linePower);

  float circ = (fract(log2(cmod)) - 0.5) * 2.0;
  circ = pow(abs(circ), linePower);

  circ *= magStrength;

  vec3 rgb = hsv2rgb(vec3(carg * 0.5 / M_PI, saturation, 0.5 + 0.5 * saturation - gridStrength * grid));
  rgb *= (1.0 - circ);
  rgb += circ * vec3(1.0);
  return vec4(rgb, 1.0);
}


float x_loc(float x, float y){
    return 2.0 * M_PI * x - 2.0 * M_PI * y / M_SQRT7;
}

float y_loc(float y){
    return 4.0 * M_PI * y / M_SQRT7;
}

vec2 unit_complex_fm_angle(float a){
    return vec2(cos(a), sin(a));
}

vec2 polar_to_complex(vec2 polar){
    return unit_complex_fm_angle(polar.x) * polar.y;
}

/* posn: x, y coord, returns a complex */
vec2 bundle_complex(vec2 posn){
    float n = 1.0;
    float m = 0.0;
    return (unit_complex_fm_angle((2.0 * n + m) * x_loc(posn.x, posn.y) + (-2.0 * m) * y_loc(posn.y)) +
            unit_complex_fm_angle((2.0 * m + n) * x_loc(posn.x, posn.y) + (-2.0 * n) * y_loc(posn.y))) / 2.0;
}

/* returns complex from current posn in cartesian */
vec2 loc_sym_fn(vec2 posn){
    return bundle_complex(posn);
}

void main () {

	vec2 uv = gl_FragCoord.xy / resolution.xy;
	uv = uv * 2.0 - 1.0;
	uv.x *= resolution.x / resolution.y;


    vec2 z = uv;

    z = loc_sym_fn(z);

    gl_FragColor = domainColoring(z, GRID_SPACING, DC_SATUR, DC_GRID_STR, DC_MAG_STR, DC_LINE_PWR);
}


