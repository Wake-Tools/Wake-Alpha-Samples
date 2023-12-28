/*|| https://wake.tools ||                                                            || GLSL | Wake Alpha ||
  | --------------------------------------------------------------------------------------------------+-+++|>
  +-  Space                                                                                   || @ Maeiky  ||
  |---------------------------------------------------------------------------------------------------+-+++|>
  +-  An simple example to show how to use a Shadertoy code, inside wake
  |
  |   Using this shader:
  |   https://www.shadertoy.com/view/MslGWN
  |
  |   GLSL language using Sokol SHDC, please refer to:
  |   https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md
  |-----|--------|---------------------|-----------------------------|--------------------------------+-+++|>
*/
@vs vs
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
////////////////
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
//out vec4 color;
//out vec4 border;
out vec3 normal;
out flat uvec4 shape_id;
out float gray;
out float dim;
///////////////
vec3 fQRot( vec3 pt, vec4 rot) {
	return pt + 2.0*cross(rot.xyz, cross(rot.xyz,pt) + rot.w*pt);
}
//1920, 1010
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
	float _z = pos.z/iHRes.z ;//*5.0;
	gl_Position.w = 1.0-_z;
	gl_Position.z = 0.0;
	

	/////// Normals ////
	_lookat.xyz = _lookat.xyz * lookat.w; // -lookat.w; = standard normals?
    normal.rgb = _lookat;
	normal.b = 1.0-pos.w;
	normal.rg = normal.rg* pos.w;
	/////////////////////
	  
  gray = depth.x*3.0;//TODO rem x3
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

//refer to
//https://thebookofshaders.com/05/


#define fragCoord gl_FragCoord
#define pow(x,y) pow(abs(x),(y)) 

//CBS
//Parallax scrolling fractal galaxy.
//Inspired by JoshP's Simplicity shader: https://www.shadertoy.com/view/lslGWr

// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
float field(in vec3 p,float s) {
	//float strength = 7. + .03 * log(1.e-6 + fract(sin(iTime) * 4373.11));
	float strength = 8;
	float accum = s/4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 26; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

// Less iterations for second layer
float field2(in vec3 p, float s) {
	//float strength = 7. + .03 * log(1.e-6 + fract(sin(iTime) * 4373.11));
	float strength = 8;
	float accum = s/4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 18; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

vec3 nrand3( vec2 co )
{
	vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
	vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
	vec3 c = mix(a, b, 0.5);
	return c;
}


void main() {
	gl_FragDepth=gl_FragCoord.z + 1.0-dim;
	vec2 coord = fragCoord.xy;
   coord.xy -= iOffset.xy;
   coord.x -= 40;
  vec2 uv = 2. * coord.xy / iResolution.xy - 1.;
	vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
	vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
	p += .2 * vec3(sin(iTime / 16.), sin(iTime / 12.),  sin(iTime / 128.));
	
	float freqs[4];
	//Sound
	//freqs[0] = texture( iChannel0, vec2( 0.01, 0.25 ) ).x;
	//freqs[1] = texture( iChannel0, vec2( 0.07, 0.25 ) ).x;
   //freqs[2] = texture( iChannel0, vec2( 0.15, 0.25 ) ).x;
	//freqs[3] = texture( iChannel0, vec2( 0.30, 0.25 ) ).x;
   
    //Sound
	freqs[0] = sin(iTime/10.0)/10.0;
	freqs[1] = cos(iTime/10.0/1.5)/1.0;
	freqs[2] = sin(iTime/10.0/2.0)/10.0;
	freqs[3] = cos(iTime/10.0/1.0)/1.0;

	float t = field(p,freqs[2]);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	
    //Second Layer
	vec3 p2 = vec3(uvs / (4.+sin(iTime*0.11)*0.2+0.2+sin(iTime*0.15)*0.3+0.4), 1.5) + vec3(2., -1.3, -1.);
	p2 += 0.25 * vec3(sin(iTime / 16.), sin(iTime / 12.),  sin(iTime / 128.));
	float t2 = field2(p2,freqs[3]);
	vec4 c2 = mix(.4, 1., v) * vec4(1.3 * t2 * t2 * t2 ,1.8  * t2 * t2 , t2* freqs[0], t2);
	
	
	//Let's add some stars
	//Thanks to http://glsl.heroku.com/e#6904.0
	vec2 seed = p.xy * 2.0;	
	seed = floor(seed * iResolution.x);
	vec3 rnd = nrand3( seed );
	vec4 starcolor = vec4(pow(rnd.y,40.0));
	
	//Second Layer
	vec2 seed2 = p2.xy * 2.0;
	seed2 = floor(seed2 * iResolution.x);
	vec3 rnd2 = nrand3( seed2 );
	starcolor += vec4(pow(rnd2.y,40.0));
   // starcolor *= 0.25;
   starcolor *= 0;//disable
	
	fragColor = mix(freqs[3]-.3, 1., v) * vec4(1.5*freqs[2] * t * t* t , 1.2*freqs[1] * t * t, freqs[3]*t, 1.0)+c2+starcolor;

   float gray = (fragColor.r+fragColor.g+fragColor.b)/3.0;
   fragColor.a =min(gray*10.0,1.0);
}

@end

/* quad shader program */
@program space vs fs

