
//-----------------------------------------------------
// Kleinian_Anaglyph_3d_Common.glsl
//-----------------------------------------------------

#define WITH_SHADOWS
#define WITH_AO

#define BACK_COLOR vec3(.08, .16, .34) 

#define PRECISION_FACTOR 5e-4
#define MIN_DIST_RAYMARCHING .01
#define MAX_DIST_RAYMARCHING 4.
#define MAX_RAYMACING_ITERATION 132 

#define MIN_DIST_SHADOW 10.*PRECISION_FACTOR
#define MAX_DIST_SHADOW .25
#define PRECISION_FACTOR_SHADOW 3.*PRECISION_FACTOR

#define MIN_DIST_AO .5*PRECISION_FACTOR
#define MAX_DIST_AO .02
#define PRECISION_FACTOR_AO PRECISION_FACTOR

#define LIGHT_VEC normalize(vec3(.2,.7, 1.6) )

#define NB_ITERATION 7

// uncomment for 2*2 antialiasing
//#define WITH_AA

//-----------------------------------------------
//                 TEXT by Andre
//-----------------------------------------------
// Andre - https://www.shadertoy.com/view/lddXzM 
//-----------------------------------------------

float line(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba)/dot(ba,ba), 0., 1.));
}
float _u(vec2 uv,float w,float v) {
    return length(vec2(abs(length(vec2(uv.x,max(0.,-(.4-v)-uv.y) ))-w),max(0.,uv.y-.4)));
}
float _i(vec2 uv) {
    return length(vec2(uv.x,max(0.,abs(uv.y)-.4)));
}
float _l(vec2 uv) {
    uv.y -= .2;
    return length(vec2(uv.x,max(0.,abs(uv.y)-.6)));
}
float _o(vec2 uv) {
    return abs(length(vec2(uv.x,max(0.,abs(uv.y)-.15)))-.25);
}
float aa(vec2 uv) {
    uv = -uv;
    float x = abs(length(vec2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2);
    x = min(x,length(vec2(uv.x+.25,max(0.,abs(uv.y-.2)-.2))));
    return min(x,(uv.x<0.?uv.y<0.:atan(uv.x,uv.y+0.15)>2.)?_o(uv):length(vec2(uv.x-.22734,uv.y+.254)));
}
float ee(vec2 uv) {
    float x = _o(uv);
    return min(uv.x<0.||uv.y>.05||atan(uv.x,uv.y+0.15)>2.?x:length(vec2(uv.x-.22734,uv.y+.254)),
               length(vec2(max(0.,abs(uv.x)-.25),uv.y-.05)));
}
float ii(vec2 uv) {
    return min(_i(uv),length(vec2(uv.x,uv.y-.7)));
}
float kk(vec2 uv) {
    float x = line(uv,vec2(-.25,-.1), vec2(0.25,0.4));
    x = min(x,line(uv,vec2(-.15,.0), vec2(0.25,-0.4)));
    uv.x+=.25;
    return min(x,_l(uv));
}
float nn(vec2 uv) {
    uv.y *= -1.;
    float x = _u(uv,.25,.25);
    uv.x+=.25;
    return min(x,_i(uv));
}

//-----------------------------------------------
vec2 kColor;
vec4 mins;
vec4 maxs;

//knighty's pseudo kleinian
float de(vec3 p) {
    float k, scale=1.;
    for(int i=0;i<NB_ITERATION;i++) {
        p = 2.*clamp(p, mins.xyz,maxs.xyz)-p;
        k = max(mins.w/dot(p,p), 1.);
        p *= k;
        scale *= k;
    }
    float rxy = length(p.xy);
    return .7*max(rxy-maxs.w, /*abs*/(rxy*p.z) / length(p))/scale;
}

float ce(vec3 p) {
    float k,r2, orb = 1.;
    for(int i=0;i<NB_ITERATION;i++) {
        p = 2.*clamp(p, mins.xyz, maxs.xyz)-p;
        r2 = dot(p,p);
        orb = min(orb, r2);
        k = max(mins.w/r2,1.);
        p *= k;
    }
    return kColor.x + kColor.y*sqrt(orb);
}

float rayIntersect(const vec3 ro, const vec3 rd, const float prec, const float mind, const float maxd) {
    float h, t = mind;
    for(int i=0; i<MAX_RAYMACING_ITERATION; i++ ) {
        h = de(ro+rd*t);
        if (h<prec*t||t>maxd)break;
        t += h;
    }
    return t;
}

vec2 trace(const vec3 ro, const vec3 rd ) {
    float d = rayIntersect(ro, rd, PRECISION_FACTOR, MIN_DIST_RAYMARCHING, MAX_DIST_RAYMARCHING);
    return (d>0.) ? vec2(d, ce(ro+rd*d)) : vec2(-1., 1.);
}


#ifdef WITH_SHADOWS

float shadow(vec3 ro, vec3 rd) {
    float d = rayIntersect(ro, rd, PRECISION_FACTOR_SHADOW, MIN_DIST_SHADOW, MAX_DIST_SHADOW);
    return (d>0.) ? smoothstep(0., MAX_DIST_SHADOW, d) : 1.;
}

#endif


#ifdef WITH_AO

float calcAO4(const vec3 pos, const vec3 nor ) {
    float hr, occ = 0., sca = 1.;
    for(int i=0; i<5; i++ ) {
        hr = MIN_DIST_AO + MAX_DIST_AO*float(i)/4.;
        occ += -(de( nor * hr + pos)-hr)*sca;
        sca *= .95;
    }
    return clamp(1. - 10.*occ, 0., 1.);    
}

#endif


vec3 calcNormal(const vec3 pos, const float t ){
    vec3 e = (PRECISION_FACTOR * t * .57) * vec3(1, -1, 0);
    return normalize(e.xyy*de(pos + e.xyy) + 
		     e.yyx*de(pos + e.yyx) + 
		     e.yxy*de(pos + e.yxy) + 
             e.xxx*de(pos + e.xxx) );
}

vec3 RD(const vec3 ro, const vec3 ww, const vec3 vv, const vec3 uu
       ,const vec2 xy, const vec2 r, const float fov) 
{ 
    vec3 er = normalize(vec3((2. * (xy.x/r.x) - 1.)* r.x/r.y,  (2. * (xy.y/r.y) - 1.), fov));
    return normalize( er.x*uu + er.y*vv + er.z*ww );
}

vec4 renderScene(const vec3 ro, const vec3 rd) 
{  
  vec3 col = BACK_COLOR;
  vec2 res = trace(ro, rd);
  float t = res.x;

  vec3 pos = ro + t*rd,
       nor = calcNormal( pos, t),
       ref = reflect( rd, nor),
       lig = LIGHT_VEC;
  // Color
  col = .5 + .5*cos( 6.2831*res.y + vec3(0,1,2) ); 

  // lighting        
  #ifdef WITH_AO
    float occ = calcAO4(pos, nor);
  #else
    float occ = 1.;
  #endif

  #ifdef WITH_SHADOWS
    float sh = .2+.8*shadow( pos, lig); //, 0.1, t );
  #else
    float sh = 1.;
  #endif

  #ifdef ONLY_AO
    col = (vec3)occ*(.5+.5*sh);
  #else

    float amb = .3;
    float dif = clamp( dot( nor, lig ), 0., 1.);
    float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.,-lig.z))), 0., 1. )*clamp( 1.-pos.y,0.,1.);
    float dom = smoothstep( -.1, .1, ref.y );
    float fre = clamp(1.+dot(nor,rd),0.,1.);
    fre *= fre;
    float spe = pow(clamp( dot( ref, lig ), 0., 1. ),99.);

    vec3 lin = vec3(.3) + 
        + 1.3*sh*dif*vec3(1.,0.8,0.55)
        + 2.*spe*vec3(1.,0.9,0.7)*dif
        + .5*occ*( .4*amb*vec3(0.4,0.6,1.) +
                  .5*sh*vec3(0.4,0.6,1.) +
                  .25*fre*vec3(1.,1.,1.));

    col *= lin;

  #endif
  // Shading.
  float atten = 1./(1. + t*.2 + t*.1); // + distlpsp*distlpsp*0.02
  col *= atten*col*occ;
  col = mix(col, BACK_COLOR, smoothstep(0.2, 1., t/MAX_DIST_RAYMARCHING));
  return vec4((col),t);
}

// - Interpolation ----------------------------------------------

#define NB 16

float[] 
  camx = float[] ( .2351, 1.2351, 1.2351, 1., .2, .41, /*.545,.545,*/ .5,.084,.145,  3.04,.12, .44,.44,.416, -1.404, .21,.2351, .2351),
  camy = float[] (-.094,  .35,     .28,  .38,  .04, .11, /*-.44,-.44,*/.35,.0614,.418, 1.,-.96, .67,.8,.0, -1., -.06,-.094),
  camz = float[] ( .608,  .608,    .35,   .3608, -.03, .48,/*.032,.032,*/ .47,0.201,.05,.28,.3, 1.445,1.,1.4, 2.019, .508,.608),

  lookx = float[] (-.73, -.627, -1., -.3, -1., -.72, /*-.82,-.82,*/-.67,-.5,-.07,-.67,-.27, -.35,-.35,-.775, .08, -.727),
  looky = float[] (-.364, -.2,   -.2,  -.2,  0., -.39, /*-.5, -.5,*/-.56,-.37,-.96,-.74,-.94, -.35,-.35,-.1, .83,-.364),
  lookz = float[] (-.582, -.582, -.5, -.35, -.0, -.58, /*-.2776,-.2776,*/-.48,-.79,-.25,.06,-.18, -.87,-.87,.23, .55, -.582),

  minsx = float[] (-.3252,-.3252,-.3252,-.3252,-.3252,-.3252,/*-.3252,-1.1,*/ -1.05,-1.05,-1.21,-1.22,-1.04,-0.737,-.62,-10., -.653,  -.653, -.3252),
  minsy = float[] (-.7862,-.7862,-.7862,-.7862,-.7862,-.7862,/*-.7862,-.787,*/ -1.05,-1.05,-.954,-1.17,-.79,-0.73,-.71,-.75, -2.,   -2., -.7862),
  minsz = float[] (-.0948,-.0948,-.0948,-.0948,-.0948,-.0948,/*-.0948,-.095,*/-0.0001,-0.0001,-.0001,-.032,-.126,-1.23,-.85,-.787, -.822, -1.073, -.0948),
  minsw = float[] ( .69, .69, .69, .69, .69, .678, /*.678,  .678,*/.7,.73,1.684,1.49,.833, .627,.77,.826,  1.8976, 1.8899, .69),

  maxsx = float[] ( .35,.3457,.3457,.3457,.3457, .3457,/*.3457,.3457,*/ 1.05,1.05,.39,.85,.3457,.73,.72,5., .888,  .735, .35),
  maxsy = float[] (1.,1.0218,1.0218,1.0218,1.0218,/*1.0218,1.0218,*/1.0218,1.05,1.05,.65,.65,1.0218,0.73,.74,1.67, .1665, 1.),
  maxsz = float[] (1.22,1.2215,1.2215,1.2215,1.2215,1.2215,/*1.2215,1.2215, */1.27,1.4,1.27,1.27,1.2215,.73,.74,.775, 1.2676, 1.22),
  maxsw = float[] ( .84, .84, .84, .84, .84, .9834,/*.9834,.9834,*/.95,.93,2.74,1.23,.9834, .8335,.14,1.172, .7798, .84);

// Deph of field animation
float[] deph = float[] ( 1.,.65,.6,.4,.2,.4,/*.055,.055,*/.65,.11,.13,1.3,.49,1.2,1.2,.5,.65,.45,1.,1.);

void commonRender(out vec4 fragColor, vec2 fragCoord, bool left, float time, vec2 res)
{
    float kt = smoothstep(0.,1.,fract(time));

    // - Interpolate positions and fractal configuration ---------------------
    int  i0 = int(time)%NB, i1 = i0+1;

    vec4 csum = vec4(0);
    vec2 q = fragCoord / res; 
#ifdef WITH_AA
    for (int ii=0;ii<2;ii++)
     for (int jj=0;jj<2;jj++) 
      { q = (fragCoord+.5*vec2(ii,jj))/res;
#endif            
    
    float d1 = left ? -0.0025 : +0.0025;   
    float d2 = left ? -0.0001 : +0.0001;

    vec3 ro = mix(vec3(camx[i0],camy[i0],camz[i0]), vec3(camx[i1],camy[i1],camz[i1]), kt),
    ww = mix(vec3(lookx[i0],looky[i0],lookz[i0]), vec3(lookx[i1],looky[i1],lookz[i1]), kt), 
    vv = -normalize(cross(ww, vec3(0,1,0))),
    uu = -normalize(cross(vv,ww)),
    er = vec3((2. * q.x - 1.) * res.x/res.y,  (2. * q.y - 1.), 3.),
    rd = normalize(er.x*uu + er.y*vv + er.z*ww );

    //---------------------------------------------
    
    ro += uu * d1,
    ww = mix(vec3(lookx[i0],looky[i0],lookz[i0]), vec3(lookx[i1],looky[i1],lookz[i1]), kt), 
    vv = -normalize(cross(ww, vec3(0,1,0))),
    uu = -normalize(cross(vv,ww)),
    er = vec3((2. * q.x - 1.) * res.x/res.y,  (2. * q.y - 1.), 3.),
    rd = normalize(er.x*(uu - d2) + er.y*vv + er.z*ww );
   
    //---------------------------------------------
    
    mins = mix(vec4(minsx[i0],minsy[i0],minsz[i0],minsw[i0]), vec4(minsx[i1],minsy[i1],minsz[i1],minsw[i1]), kt),
    maxs = mix(vec4(maxsx[i0],maxsy[i0],maxsz[i0],maxsw[i0]), vec4(maxsx[i1],maxsy[i1],maxsz[i1],maxsw[i1]), kt);

    kColor = vec2(.25,1.);
 
    // - Rendering -----------------------------------------------------------    
    csum += renderScene(ro, rd);
            
#ifdef WITH_AA
    }
    csum /= 4.;
#endif
    fragColor = csum;
}