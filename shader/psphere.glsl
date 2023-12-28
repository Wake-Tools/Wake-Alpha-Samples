/*|| https://wake.tools ||                                                            || GLSL | Wake Alpha ||
  | --------------------------------------------------------------------------------------------------+-+++|>
  +-  Perfect Spheres                                                                         || @ Maeiky  ||
  |---------------------------------------------------------------------------------------------------+-+++|>
  +-  This is a simple idea of using a gradiant with depth to create perfect sphere
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
  // mat4 mvp;
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
out vec3 pos;
out vec3 upos;
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

   float iID_pc = gl_InstanceID;
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
   pos = position.xyz;
   pnorm = vec3(0,0,1);

   pos.xyz += inst_pos;
   upos=inst_pos;
   //float rowx = mod(iID_pc*100.0, 4);
   //pos.x += rowx;
   //pos.y += iID*100.0;

   pos.y -= 0;
   //pos *= 0.5;
   
	shape_id = id;
   
   gl_Position.xy = pos.xy/iHRes.xy; 
	gl_Position.y *= -1;
	float _z = pos.z/iHRes.z ;//*5.0;
	gl_Position.w = 1.0-_z;
	gl_Position.z = (0.5-(_z)/iResolution.z )*gl_Position.w;
   //gl_Position *= mvp;
}
@end


///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///--------------------------------------------------------------------------------------------
///==|FRAGMENT|==
///============================================================================================
///--------------------------------------------------------------------------------------------

/* quad fragment shader */
@fs fs
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
  // mat4 mvp;
   float  iNbInst;   // Numbers of instances
   float  iNbPerInst;   // Numbers of instances
};

struct Light // user defined structure.
{
  vec3 pos;
  vec3 c_spec;
  vec3 c_diffuse;
};

///////////////
///== IN ==///
//in vec4 border;
in vec3 pnorm;
in vec3 normal;
in vec3 pos;
in vec3 upos;
in flat uvec4 shape_id;
in float gray;
in float dim;
in vec2 sh_uv;
///////////////
///== OUT ==///
out vec4 frag_color;
///////////////
float rand(float n){return fract(sin(n) * 43758.5453123);}


vec3 getcolor(float x, float y){
   float dx2 = abs(x);
   float dy2 = abs(y);
   float d2  = 1.0-sqrt(dx2*dx2+dy2*dy2);
   
   float pp = d2*0.012;
   float cdx = (sin(pp*upos.x)/2);//*sin(dx+iTime);
   float cdy = (sin(pp*upos.y)/2);//*sin(dy+iTime);
   float cd  = sin(sqrt(cdx*cdx+cdy*cdy));
   vec3 color = vec3(rand(floor(cd*2*8)), rand(floor(cd*3*8)),rand(floor(cd*5*8)) );
   color.xyz*=  (vec3(sin(upos.x)/PI*2,0.5,0.5))*1.5;
   return color;
}

void main() {
vec3 c = vec3(1.0,0.0,1.0);
vec3 p =  upos;
p.y*=-1;
float dim = 50;
///
float dx = abs(sh_uv.r-0.5);
float dy = abs(sh_uv.g-0.5);
float d  = 1.0-sqrt(dx*dx+dy*dy);
frag_color.a = smoothstep(0.52,0.53 ,d);
///
vec3 FragPos  = p + vec3(  ((sh_uv.x-0.5))*dim, ((sh_uv.y-0.5))*dim, d*dim*20);

  // frag_color.g =rand(d);
  // frag_color.b =rand(d);
   gl_FragDepth+= frag_color.r/60 +  1.0-d + mod( d, 0.01);//rugness
   //	gl_FragDepth=p.z;//rugness

	//float normT = dot(normal, vec3(0.0,1.0,0.0));//+0.5;
	//float normB = 1.0-dot(normal, vec3(0.0,-1.0,0.0));
   
   vec3 norm = vec3( (sh_uv.x-0.5)*2 ,(sh_uv.y-0.5)*2, d);
   float rr = rand(floor(pos.x*20*3));

   float delta = 0.07;
   float delta2 = 0.02;
   vec3 color1 = getcolor( sh_uv.r+ sin(upos.x+iTime)/4,  sh_uv.g+ sin(upos.y+iTime)/4);
   vec3 color2 = getcolor( sh_uv.r+delta2+ sin(upos.x+iTime+delta)/4,  sh_uv.g+ sin(upos.y+iTime+delta)/4);
   vec3 color3 = getcolor( sh_uv.r+ sin(upos.x+iTime-delta)/4,  sh_uv.g+delta2+ sin(upos.y+iTime-delta)/4);
   vec3 color = (color1 + color2+color3)/3;
   
   vec3 vlight = vec3(0.0,  0.0, 1.0);

   float mx = (iMouse.x/iResolution.x-0.5)*2;
   float my = (iMouse.y/iResolution.y-0.5)*2;
   
  // vlight=rotate(vlight,q_yaw(q_pitch(q_new(),-my),-mx));
   
   vec4 q = q_new();
   q = q_yaw(q, -mx);
   q = q_pitch(q, -my);
   vlight=rotate(vlight,q);

  float ldir =  dot(norm, vlight);

   vec3 viewPos = vec3(0,0,-1000);
   vec3 lightPos = vec3(sin(iTime)*1000, 0, cos(iTime)*500);


   vec3 viewDir = normalize(viewPos-FragPos);
   vec3 lightDir = normalize(lightPos -FragPos);  
   vec3 reflectDir = reflect(-lightDir, norm);  
   float specularStrength = 10000;
   vec3 lightColor = vec3(1,1,1);

   float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
   vec3 specular = specularStrength * spec * lightColor;  
   float att = d*d*d*d*d*d*d;
   frag_color.rgb = (0.5+specular)*color*att;


   Light avLight_Position[5];//float avLight_Position[] = {(vec4(0.5, 0.5, 0.5, 0.5)}; //.w .a = Constant Attenuation / alpha
   avLight_Position[0].pos= ( vec3(sin(iTime)*1000.0, 0, -(cos(iTime)*1000))); //.w .a = Constant Attenuation / alpha
   avLight_Position[0].c_spec=  vec3(1.0,0.0,0.0 )*50;
   avLight_Position[0].c_diffuse=  vec3(1.0,0.0,0.0 );

   avLight_Position[1].pos= ( vec3(sin(iTime)*1000.0, (cos(iTime)*1000), 0)); //.w .a = Constant Attenuation / alpha
   avLight_Position[1].c_spec=  vec3(0.0,1.0,0.0 )*10;
   avLight_Position[1].c_diffuse=  vec3(0.0,1.0,0.0 )*0.3;

   avLight_Position[2].pos=  vec3(0, (sin(iTime)*1000), cos(iTime)*1000.0); //.w .a = Constant Attenuation / alpha
   avLight_Position[2].c_spec=  vec3(0.0,0.0,1.0 )*20;
   avLight_Position[2].c_diffuse=  vec3(0.0,0.0,1.0 )*0.3;


   vec3  vColorSpecular = vec3(1.0,0.0,0.0 )*10;
   vec3  vColorDiffuse = vec3(1.0, 0.0, 0.0);  //rgb -1 to 2  no diffuse : vec4(0.0,0.0,0.0, 1.0); normal : vec4(1.0,1.0,1.0, 1.0);

   vec3 vDark;
   vec3 vLight;

   vec3 vPtWorld  = p + vec3(  ((sh_uv.x-0.5))*dim, ((sh_uv.y-0.5))*dim, d*dim);
   vec3 vPersp  =  (vec3(  0,0,-1000));

   vec3 V = normalize( vPtWorld - vPersp  );//view direction

   vec3 L = normalize( vPtWorld -avLight_Position[0].pos.xyz     );
   float LdotN = normalize(max(0.0, dot(L,norm)));
   //float LdotN = -dot(L,norm); //temp


   #define MAX_LIGHT 20
   float iTotalLight =3;

   //0 to 1
   float att_kC = 0.1; //Kc is the constant attenuation
   float att_kL = 0.00005; //KL is the linear attenuation
   float att_kQ = 0.00000008; //KQ is the quadratic attenuation

   vec3 vAmbient = vec3(0.0, 0.0, 0.0); // -1.0 to 1.0
    norm = normalize(vec3( (sh_uv.x-0.5) ,(sh_uv.y-0.5), d));
       
   float _nGAtt = 0.0;
   float _nGDiffuse = 0.0;
   float _nGSpecular = 0.0;

   vec3 gspec = vec3(0,0,0);
   vec3 gdiffuse = vec3(0,0,0);
   int i = 0;
   float nDiffuseTranslucidity  = 0;

   for (int i = 0; i < iTotalLight && i < MAX_LIGHT; ++i)  {
      //diffuse
      vec3 nLDir = normalize( vPtWorld -avLight_Position[i].pos.xyz     );//light direction
      float nLdotN =  (dot(norm, nLDir));
      if(nLdotN < 0.0){
         nLdotN *= nDiffuseTranslucidity; //Must be negative
      }

      float diffuse = 0.5 * nLdotN; //0.5 Just a random material
      gdiffuse += diffuse*avLight_Position[i].c_diffuse;

      //attenuation
      float dd = distance( (avLight_Position[i].pos.xyz),  (vPtWorld.xyz) );
      att = 1.0 / (att_kC + dd * att_kL + dd*dd*att_kQ);
      _nGAtt += att;

      float force = 32;

      //Blinn-Phong
      vec3 viewDir_ = normalize(vPtWorld - vPersp.xyz  );
      vec3 reflectDir_ = reflect(-nLDir, norm);  
      float s =  pow(max(0.0, dot(viewDir_, reflectDir_)), force); //pow = shininess https://learnopengl.com/img/lighting/basic_lighting_specular_shininess.png
      gspec += avLight_Position[i].c_spec*s;
   }
   
   float _strenght = 10;

   float attt = d*d*d*d;
   attt*=attt;
   //frag_color.rgb = (_nGDiffuse+_nGSpecular)*color*_nGAtt;
   frag_color.rgb = (0.5+gdiffuse+gspec)*color*_nGAtt*attt;

   frag_color.a-=0.25;

}
@end

@program psphere vs fs

