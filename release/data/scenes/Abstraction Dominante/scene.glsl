//-----------------------------------------------------------------------------
// Frameworks
//-----------------------------------------------------------------------------
varying vec2 v;
uniform float time,bassTime,bass,CC[4];
uniform sampler2D rnd, tex, tule;

float t = 0.;

float random1f(float n)
{
    return fract(sin(n)*33753.545383);
}
float Hash( float n )
{
    return fract(sin(n)*33753.545383)*2.-1.;
}

const float PI = 3.141592654;
vec2 t3(inout vec2 x,float y)
{
    return x=x*cos(y)+sin(y)*vec2(-x.y,x.x);
}
float map( in vec3 p )
{
    float ss = 1.7+cos(bassTime*.8)*.3;
    float scale = 1.;
    
    for( int i=0; i<7;i++ )
    {
        p = -1.0 + 2.*fract(0.5*p+0.5);

        float r2 = dot(p,p);
        
        float k = max(ss/r2,0.1);
        p.xz = t3(p.xz,.7*CC[0]+bassTime*CC[1]*5.0);
        p     *= k;
        scale *= k;
    }
    
    return 0.25*length(p)/scale;
}





vec3 color( in vec4 p, in vec3 n, in vec3 org, in vec3 dir, in int nbIte )
{
    vec2 uv = v;
    if(abs(uv.x)*2.+uv.y>1.)
        uv.y = mix(uv.y,-uv.y,bass*5.);
    vec3 col = vec3(0.);

    vec3 cold = vec3(1.-uv.x*.2-.2, uv.x*.3+.7, 1.+uv.x*.3+.3);
    vec3 hot = vec3(-uv.y*.1+.9,uv.y*.3+.7,.3); 
    vec3 bckgrnd = mix(cold,hot,CC[3]); 

    col = mix(col, vec3(1.), min(pow(length(p.xyz-org)/50.,1.),1.));  
    col += bckgrnd * p.w*.5;

    col = mix(vec3((col.r+col.g+col.b)/3.), col, CC[2]);
    return col;
}





vec4 raymarche(in vec3 org, in vec3 dir, in vec2 nearFar, in int nbStep, in float eps)
{
    float pass = 1./float(nbStep);
    float d = 0.0, accd = 0.0;
    vec4 p = vec4(org+dir*nearFar.x,0.);
    for(int i=0; i<nbStep; i++)
    {
        d = abs(map(p.xyz));
        accd += d;
        
        p.xyz += dir*d;
        p.w += pass;
        
        if( d<eps || accd > nearFar.y)
            break;
    }
    
    return p;
}

vec3 normal( in vec3 p )
{
    vec3 eps = vec3(0.000001,0.0,0.0);
    return normalize(vec3(
        map(p+eps.xyy)-map(p-eps.xyy),
        map(p+eps.yxy)-map(p-eps.yxy),
        map(p+eps.yyx)-map(p-eps.yyx)
    ));
}

//-----------------------------------------------------------------------------
// Main functions
//-----------------------------------------------------------------------------
mat3 lookat(vec3 fw,vec3 up){
  fw=normalize(fw);
  vec3 rt=normalize(cross(fw,normalize(up)));
  return mat3(rt,cross(rt,fw),fw);
}

vec3 getCamPos()
{
    return vec3(1.,1., -time -bassTime*5.0 );
}
vec3 getCamDir(vec2 uv)
{
    vec3 dir = vec3( normalize( vec4(uv.xy*vec2(16.0/9.0,1),-1.5+length(v)*1.5,0.0) ) );
    dir.xz = t3(dir.xz,cos(time*.1 + bassTime*3.0));
    dir.xy = t3(dir.xy,.25);
    dir.yz = t3(dir.yz,.25);
    return dir;
}
void main()
{

    vec3 col = vec3(0.);
    
        
        vec3 org = getCamPos();
        vec3 dir = getCamDir(v);
        
        vec4 p = raymarche(org,dir, vec2(.5,20.), 64, 0.001);
        vec3 n = normal(p.xyz);
        col += color(p,n, org,dir, 5);
        
        
    //Gamma correction
    col = pow( col*1.3, vec3(2.) );
    gl_FragColor = vec4(col, p.w);
}




