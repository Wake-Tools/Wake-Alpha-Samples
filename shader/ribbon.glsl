/*|| https://wake.tools ||                                                            || GLSL | Wake Alpha ||
  | --------------------------------------------------------------------------------------------------+-+++|>
  +-  Ribbon                                                                                  || @ Maeiky  ||
  |---------------------------------------------------------------------------------------------------+-+++|>
  +-  Create a 3d ribbon with a lot of simple quad
  |
  |   GLSL language using Sokol SHDC, please refer to:
  |   https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md
  |-----|--------|---------------------|-----------------------------|--------------------------------+-+++|>
*/

@ctype mat4 hmm_mat4
@include glsl_inc/commun.ginc

@vs vs
@include_block  quaternion
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
   mat4 mvp;
   float  iNbInst;   // Numbers of instances
   float  iNbPerInst;   // Numbers of instances
};

///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///==|VERTEX|==
///============================================================================================
///--------------------------------------------------------------------------------------------

//////////////
///== IN ==///
in vec4 position;
in vec4 lookat;
in vec4 lookatV;
in vec2 depth;
in uvec4 id;
in vec3 inst_pos;

///////////////
///== OUT ==///
out vec3 pnorm;//plane normal
out vec3 normal;
out flat uvec4 shape_id;
out float gray;
out float dim;
out vec2 sh_uv;
///////////////

#define apply_rot(_q) pnorm= rotate(pnorm,_q);pos.xyz=rotate(pos.xyz,_q);

void main() {
   vec3 iHRes = vec3(iResolution.x,iResolution.y, iResolution.x*4)/2.0;
   /// UNIFORM USE (KEEP ALIVE) ///
   gl_Position.w =  iMouse.x;

   ////////////////////////////////
   float mx = iMouse.x/iHRes.x*2;
   float pID = floor(gl_VertexID/4.0);
   float iID = gl_InstanceID;

   // float iID_pc = gl_InstanceID/iNbInst;
   float iID_pc = gl_InstanceID;
   // float iID = 1.0;
   // float iID = 1.0;
   float nbElements = iNbInst*iNbPerInst;

   //  iID_pc =   iID_pc-(floor(iID_pc/1600)*1600);
   iID_pc =   mod(iID_pc, iNbPerInst)/iNbPerInst;

   float rnd=  mod(iID_pc, 0.00002)*300.0;
   iID_pc+=rnd;
   // iID_pc =   2.0;
   float rnd2 = mod(iID_pc, 0.00002)*3000.0;

   uint ivid = gl_VertexID;
   //int vID = (int)mod( ivid , 4);
   uint vID = ivid%4;
   
   switch (vID) {
      case 0:
      sh_uv = vec2(0,0);
      break;
      case 1:
      sh_uv = vec2(1,0);
      break;
      case 2:
      sh_uv = vec2(1,1);
      break;
      case 3:
      sh_uv = vec2(0,1);
      break;
   }
  
   float rot = iTime;
   vec4 pos = position;
   pnorm = vec3(0,0,1);

   vec4 q = q_new();

   float range = 0.1;
   float sel = mod(iTime*300.0, 1000)/1000.0;
   if(iID_pc > sel &&  iID_pc<sel +range ){
   float p = (iID_pc - sel)/range;
      pos.y += 1.0+sin(abs(p-0.5))*50;
   }

   q = q_yaw(q, R90);

apply_rot(q);
      
   pos.x += 200;
   pos.y += 40;
   
   q = q_new();
   q = q_yaw(q, (iID_pc * PI*2+rot));
   
apply_rot(q);

   pos.x+=000;
   pos.xyz += inst_pos;
   pos.xyz *= 1;


   pos.y += iID*1.0;
   pos*=0.5;
   pos.y -= 300;
	shape_id = id;
   
   gl_Position.xy = pos.xy/iHRes.xy; 
	gl_Position.y *= -1;
	float _z = pos.z/iHRes.z ;//*5.0;
   
	gl_Position.w = 1.0-_z;
	gl_Position.z = (0.5-(_z)/iResolution.z )*gl_Position.w;
   // gl_Position *= mvp;
}
@end

///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///==|FRAGMENT|==
///============================================================================================
///--------------------------------------------------------------------------------------------

/* quad fragment shader */
@fs fs

///////////////
///== IN ==///
//in vec4 border;
in vec3 pnorm;
in vec3 normal;
in flat uvec4 shape_id;
in float gray;
in float dim;
in vec2 sh_uv;
///////////////
///== OUT ==///
out vec4 frag_color;
///////////////

void main() {
	vec3 c = vec3(1.0,0.0,1.0);
   
   float normT = pnorm.b;//+0.5;
	float normB = pnorm.b*-1.0;
   
   float pnormL = dot(pnorm, vec3(0.0, 0.0, 1.0)); //Light dir
	float ldir = ( (pnormL) );
   normT=ldir;
   normB=ldir*-1;
   
	//float light = smoothstep(0.7,1.0,normT) +1.0 ;
	float light = (smoothstep(0.6, 0.65,normT)-smoothstep(0.65, 0.85,normT))*0.1 ;
	float dark =( smoothstep(0.5, 0.1,normB)) ;
   
   light+=ldir/2.0;
	frag_color.rgb = (((1.0-c) * light) + c) * dark;
   
   //frag_color.rgb *= ldir;
   frag_color.rgb*= smoothstep(0.0,0.3,sh_uv.x)*1.5;
   frag_color.rgb*= smoothstep(0.0,0.3,sh_uv.y)*1.5;
   frag_color.rgb*= smoothstep(0.0,0.3,1.0-sh_uv.y)*1.5;
      
  
   float nb = 1.0-abs(0.5-pnorm.b)*2;
   float ngh  = abs(pnorm.g-1.0);
   
   frag_color.rgb = pnorm.rgb;
   
 	frag_color.a = 1.0;//disable alpha
}
@end

@program ribbon vs fs

