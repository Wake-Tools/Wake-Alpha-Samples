/*|| https://wake.tools ||                                                            || GLSL | Wake Alpha ||
  | --------------------------------------------------------------------------------------------------+-+++|>
  +-  Eye                                                                 || @ Maeiky / Felipe Tovar-Henao ||
  |---------------------------------------------------------------------------------------------------+-+++|>
  +-  Basic eye using only a shader, so it can be integraded in another more complex shape
  |
  |    From this shader:
  |    https://www.shadertoy.com/view/7tjSWy  (Felipe Tovar-Henao)
  |
  |   GLSL language using Sokol SHDC, please refer to:
  |   https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md
  |-----|--------|---------------------|-----------------------------|--------------------------------+-+++|>
*/

@vs v

///////////////////
///== UNIFORM ==///
uniform vs_params {
   vec4 iMouse;      // mouse pixel coords .xy: current (if MLB down), zw: click
   vec3 iResolution; // viewport resolution (in pixels)
   vec3 iOffset;     // viewport offset (in pixels)
   float iTime;      // shader playback time (in seconds)
   float iTimeDelta; // render time (in seconds)
   float iFrameRate; // shader frame rate
   //int   iFrame;   // shader playback frame
   //float iChannelTime[4];
   //vec3  iChannelResolution[4];
   //samplerXX iChannel0..3;
   //vec4 iDate        //(year, month, day, time in seconds)
};

//////////////
///== IN ==///
in vec4 position;
//in vec4 color0;
in vec4 lookat;
in vec4 lookatV;
in vec2 depth;
in uvec4 id;

///////////////
///== OUT ==///
out vec3 normal;
out flat uvec4 shape_id;
out float gray;
out float dim;
///////////////
vec3 fQRot( vec3 pt, vec4 rot) {
	return pt + 2.0*cross(rot.xyz, cross(rot.xyz,pt) + rot.w*pt);
}
void main() {
	vec3 iHRes = vec3(iResolution.x,iResolution.y, iResolution.x)/2.0;
	/// UNIFORM USE (KEEP ALIVE) ///
	gl_Position.w =  iMouse.x;
	////////////////////////////////
	float mx = iMouse.x/iHRes.x*2;
	//Quaternion
	vec4 pos = position;

	shape_id = id;
	
	vec3 _lookat = lookat.xyz - pos.xyz;
	_lookat = normalize(_lookat);

   gl_Position.xy = pos.xy/iHRes.xy; 

	gl_Position.y *= -1;
	gl_Position.w = 1.0;

	gl_Position.w = pos.z;
	float _z = pos.z/iHRes.z ;

	gl_Position.w = 1.0-_z;
	gl_Position.z = 0.0;
	
	/////// Normals ////
   _lookat.xyz = _lookat.xyz * lookat.w; // -lookat.w; = standard normals?
   normal.rgb = _lookat;
   normal.b = 1.0-pos.w;
   normal.rg = normal.rg* pos.w;
	/////////////////////

   dim =  depth.y/iHRes.z*gray+_z+0.5; 
}
@end


/* quad fragment shader */
@fs fs

uniform vs_params {
   vec4 iMouse;      // mouse pixel coords .xy: current (if MLB down), zw: click
   vec3 iResolution; // viewport resolution (in pixels)
   vec3 iOffset;     // viewport offset (in pixels)
   float iTime;      // shader playback time (in seconds)
   float iTimeDelta; // render time (in seconds)
   float iFrameRate; // shader frame rate
   //int   iFrame;   // shader playback frame
   //float iChannelTime[4];
   //vec3  iChannelResolution[4];
   //samplerXX iChannel0..3;
   //vec4 iDate        //(year, month, day, time in seconds)
};
///////////////
///== IN ==///
//in vec4 color;
//in vec4 border;
in vec3 normal;
in flat uvec4 shape_id;
in float gray;
in float dim;
///////////////
///== OUT ==///
out vec4 fragColor;
///////////////


#define pow(x,y) pow(abs(x),(y)) 
#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define edge 0.005


/* -------- SHAPERS/MISC -------- */
float fold(in float x) {
    return abs(mod(x+1.0,2.0)-1.0);
}

float reliRamp(in float x, in float s) {
    return floor(x) + clamp((max(1.0, s)*(fract(x) - 0.5)) + 0.5, 0.0, 1.0);
}

float cosine_ramp(in float x, in float s) {
    float y = cos(fract(x)*3.14159265359);
    return floor(x) + 0.5 - (0.5*pow(abs(y), 1.0/s)*sign(y));
}
float camel_ramp(in float x, in float s) {
    float y = fract(x);
    return floor(x) + pow(0.5 - (0.5 * cos(6.28318530718*y) * cos(3.14159265359*y)), s);
}

vec2 rotate2D(in vec2 vUV, in float theta) {
    return vUV * mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
}

float scale(in float x, in float inmin, in float inmax, in float outmin, in float outmax) {
    return ((x-inmin)/(inmax-inmin))*(outmax-outmin)+outmin;
}

/* -------- NOISE -------- */
float random1D(in vec2 vUV, in int seed) {
    return fract(abs(sin(dot(vUV, vec2(11.13, 57.05)) + float(seed)) * 48240.41));
}


float value_noise(in vec2 vUV, in int seed) {
    vec2 x = floor(vUV);
    vec2 m = fract(vUV);

    float bl = random1D(x, seed);
    float br = random1D(x + vec2(1.0, 0.0), seed);
    float tl = random1D(x + vec2(0.0, 1.0), seed);
    float tr = random1D(x + vec2(1.0, 1.0), seed);

    vec2 cf = smoothstep(vec2(0.0), vec2(1.0), m);

    float tm = mix(tl, tr, cf.x);
    float bm = mix(bl, br, cf.x);

    return mix(bm, tm, cf.y);
}

/* -------- EYE FUNCTIONS -------- */
float eyeSDF(in vec2 vUV, in float s) {
    float o = 0.125;
    vec2 uv = abs(vUV*vec2(1. + o, 1.0));
    float x = clamp(uv.x*(1.-o),0.0,0.5);
    uv -= vec2(0.5, pow(cos(x*PI)/s, s));
    return length(max(vec2(0.0), uv)) + min(0.0, max(uv.x, uv.y));
}

vec4 mk_tearduct(in float sdf, in float t) {
    vec3 col = mix(vec3(0.0, 0.0, 0.0), vec3(0.8471, 0.8471, 0.8471), cosine_ramp(fold(sdf*60.0 + t*0.25), 2.0));
    float a = smoothstep(edge, 0.0, sdf+edge);
    return vec4(col, a);
}

vec4 mk_eyelids(in float sdf) {
    return smoothstep(edge*2.0, 0.0, abs(sdf)-0.01) * vec4(0.6471, 0.6471, 0.6471, 1.0);
}

vec4 mk_sclera(in vec2 vUV, in float d, in float t) {

    float g = rotate2D(vUV, length(vUV)*TWO_PI*sin(t*0.1) + t*0.01).y;
    vec3 glow   = smoothstep(edge, 0.0, g) * vec3(0.1);
    //vec4 sclera = smoothstep(edge, 0.0, d-0.25) * vec4(0.8275, 0.8235, 0.8235, 1.0);
    vec4 sclera =  vec4(0.8275, 0.8235, 0.8235, 1.0);
    //vec4 border = smoothstep(edge, 0.0, abs(d-0.25)-0.0025) * vec4(0.2549, 0.2549, 0.2549, 1.0);
    //sclera.rgb = mix(sclera.rgb, glow, glow.r);
    //sclera = mix(sclera, border, border.a);
    return sclera;
}

vec4 mk_iris(in vec2 vUV, in float d, in float t) {

    float a = atan(vUV.x, vUV.y);
    vec3 col = mix(vec3(0.6784, 0.7922, 0.8431), vec3(0.6118, 0.7255, 0.7804), fold(cosine_ramp(sin(a*3.0*cos(a*2.0)+t*0.5), 4.0)));
    col = mix(col, vec3(0.9765, 0.8196, 0.8392), cosine_ramp(cos(3.0*a*sin(-a*1.5) + t*0.4)* 0.5 + 0.5, 4.0));
    vec4 iris = smoothstep(edge, 0.0, d-0.125) * vec4(col, 1.0);
    vec4 border = smoothstep(edge, 0.0, abs(d-0.125)-0.002) * vec4(0.2627, 0.2353, 0.2353, 1.0);

    float shade = cos(a+t*0.25)*0.5+0.5;
    shade *= shade;
    shade = cosine_ramp(shade, 4.0);
    iris = mix(iris, border, border.a);
    //iris.rgb = mix(iris.rgb, vec3(0.3529, 0.0627, 0.4941), shade*0.75);
    iris.rgb = mix(iris.rgb, vec3(0.3529, 0.0627, 0.4941), 0.75);
    return iris;
} 

vec4 mk_pupil(in float d, in float t) {
    t = sin(d+t*0.125)*0.01;
    return smoothstep(edge, 0.0, d-0.05+t) * vec4(0.0627, 0.0588, 0.0588, 1.0);
}

vec4 mk_glow(in vec2 vUV, in float t) {
    float d = length(vUV);
    vUV *= vec2(sin(d*2.123 - t*0.798), cos(d*3.123 + t*0.91823))*0.1 + 1.0;
    d = length((vUV-(vUV.y*0.1))-0.05);

    vec4 glow = smoothstep(edge*1.5, 0.0, d-0.03) * vec4(1.0);

    d = length((vUV-(vUV.y*0.1))+0.05);
    glow = mix(glow, smoothstep(edge*1.25, 0.0, d-0.02) * vec4(1.0), 1.0-glow.a);

    return glow;
}


float angle(vec2 _pt1, vec2 _pt2) {
   return atan(_pt1.x - _pt2.x,_pt1.y - _pt2.y);
}

vec4 mk_retina(in vec2 vUV, in float t) {

   vec4 retina = vec4(0.0);
   vUV *= length(vUV)*1.5+1.0;

   float limit=0.2;
   vec2 m = iMouse.xy/iResolution.xy- 0.5;
   if(sqrt(m.x*m.x+m.y*m.y) > limit) {
      float a =angle(m, vec2(0,0));
      m.x= sin(a)*limit;
      m.y= cos(a)*limit;

   }
   vUV.xy -=m;

    float size =0.35;
    float d = length(vUV)*(1.0-size);
    vec4 glow = mk_glow(vUV, t);
    vec4 iris = mk_iris(vUV, d, t);;
    vec4 pupil = mk_pupil(d+sin(t*0.5 + 0.12)*0.005, t);    

    retina = mix(retina, iris, iris.a);
    retina = mix(retina, pupil, pupil.a*retina.a);
    //retina = mix(retina, glow, glow.a*0.475*iris.a);
    retina += glow*0.1;
    retina.xyz += glow.xyz*0.1;
    
    return retina;
}

vec4 mk_eyeball(in vec2 vUV, in float t) {
   float d = length(vUV);
   vec4 eyeball = vec4(0.0);
   vec4 sclera = mk_sclera(vUV, d, t);
   vec4 retina = mk_retina(vUV, t + reliRamp(t, 2.0));

   eyeball = mix(eyeball, sclera, sclera.a);
   eyeball = mix(eyeball, retina, retina.a*sclera.a);
    
  // vec4 border = smoothstep(edge, 0.0, abs(d-0.25)-0.00575) * vec4(0.8, 0.8, 0.9, 0.70);
   vec4 border = (smoothstep(0.15, 1.0, 0.5-d)) * vec4(0.8, 0.8, 0.9, 0.70);
   vec4 border2 = (smoothstep(0.0, 1.0, d)) * vec4(0.8, 0.8, 0.9, 0.70);
   //eyeball = mix(eyeball, border, border.a);  
   eyeball += border*0.55;
   return eyeball;
}

vec4 mk_eye(in vec2 vUV, in float b, in float t) {
    vec4 eye = vec4(0.0);
    float eye_sdf = eyeSDF(vUV*1.06, b);
    vec4 tearduct = mk_tearduct(eye_sdf, t);
    vec4 eyelids = mk_eyelids(eye_sdf);
    vec4 eyeball = mk_eyeball(vUV, t);

    //eye = mix(eye, tearduct, tearduct.a);
    eye = mix(eye, eyeball, eyeball.a);//no tearduct
    //eye = mix(eye, eyeball, eyeball.a*tearduct.a);
    //eye = mix(eye, eyelids, eyelids.a);
    return vec4(eye);
}


void main() {
	gl_FragDepth=gl_FragCoord.z + 1.0-dim;

   vec2 coord =  gl_FragCoord.xy;
   coord.xy-=iOffset.xy;

   vec2 vUV = coord.xy / iResolution.xy;

   float scl = 1.0;
   vec4 color = vec4(0.0);
   float sdf = 1.0;
   float i = 0.0;

   vec2 iUV = floor(vUV);

   vUV.x-= 0.5;
   vUV.y-=0.5;

   vUV.y*=(iResolution.y / iResolution.x);

   float rand = value_noise(iUV, int(vUV.x*vUV.y));
   float t = (iTime + 100.0*(i+0.5)) * (rand + 1.0);
   float b = scale(pow(fold(t * 0.1), 100.0), 0.0, 1.0, 2.0, 10.0);
   vec4 eye = mk_eye(vUV, b, t * 0.5);

   color = mix(color, eye, eye.a);
   color = mix(color, vec4(0.6824, 0.6824, 0.6824, 1.0), (1.0-color.a));
   fragColor = color;
}
@end

/* quad shader program */
@program eye vs fs

