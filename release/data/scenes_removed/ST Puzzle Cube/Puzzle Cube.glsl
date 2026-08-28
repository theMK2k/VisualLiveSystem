// https://www.shadertoy.com/view/4lKyDc

const float BPM = 180.;
const float SPEED = BPM/60.;

#define PI (acos(-1.))
#define HALFPI (PI*.5)

vec2 rotate(vec2 a,float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x*c-a.y*s,
        a.x*s+a.y*c
    );
}

float sdBox(vec3 p, vec3 r)
{
    vec3 d = abs(p)-r;
    return min(max(d.x,max(d.y,d.z)),0.) + length(max(d,0.));
}

float sdRoundBox(vec3 p, vec3 r, float rr)
{
    return sdBox(p,r-rr)-rr;
}

float tick(float t)
{
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    return t;
}

float noise(float a)
{
    return fract(a*123.4762831);
}

float hash2(vec2 a)
{
    return fract(sin(dot(a,vec2(4.43243,12.4762))*13.43762));
}

vec2 splitScene(vec3 p, float spinScale)
{
    float time = iTime * SPEED;
    float t = tick(fract(time));
    float mode = noise(floor(time)) * 3.;

    float axisDirection = fract(mode)<.5?-1.:1.;
    float spinDirection = mod(mode,.5)<.25?-1.:1.;
    t *= spinDirection;

    float clipDist = 0.;

    if (mode < 1.){
        p.yz = rotate(p.yz,t*HALFPI*spinScale);
        clipDist = p.x*axisDirection-.5;
    }
    else if (mode < 2.){
        p.xz = rotate(p.xz,t*HALFPI*spinScale);
        clipDist = p.y*axisDirection-.5;
    }
    else if (mode < 3.){
        p.xy = rotate(p.xy,t*HALFPI*spinScale);
        clipDist = p.z*axisDirection-.5;
    }
    clipDist *= (1.-spinScale*2.);

    vec3 lp = mod(p+.5,1.)-.5;
    float distCubes = max(
        sdBox(p, vec3(1.5)),
        sdRoundBox(lp, vec3(.48), .04)
    );

    vec3 stickerSize = vec3(.4,.4,1);
    float stickerRadius = .05;
    float distStickers = min(
        min(
            sdRoundBox(lp,stickerSize.xyz,stickerRadius),
            sdRoundBox(lp,stickerSize.yzx,stickerRadius)
        ),
        sdRoundBox(lp,stickerSize.zxy,stickerRadius)
    );
    distStickers = max(
        distStickers,
        -sdBox(p,vec3(1.4))
    );

    distCubes = max(distCubes,clipDist);

    float color = 0.;
    color+=floor(p.x+1.5)*3.;
    color+=floor(p.y+1.5)*7.;
    color+=floor(p.z+1.5)*11.;
    color+=mode;

    return vec2(
        distCubes,
        distStickers < 0. ? 1.+color : 0.
    );
}

vec2 scene(vec3 p)
{
    vec2 a = splitScene(p,0.);
    vec2 b = splitScene(p,1.);
    return vec2(min(a.x,b.x),a.x<b.x?a.y:b.y);
}

void mainImage(out vec4 out_color, vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy - .5;
    uv.x *= iResolution.x / iResolution.y;

    vec3 cam = vec3(0,0,-10);
    vec3 dir = normalize(vec3(uv,1.5));

    cam.yz = rotate(cam.yz, sin(iTime)*.3+.3);
    dir.yz = rotate(dir.yz, sin(iTime)*.3+.3);

    cam.xz = rotate(cam.xz, iTime*.5);
    dir.xz = rotate(dir.xz, iTime*.5);

    float t = 0.;
    vec2 k;
    for (int i = 0; i < 100; ++i)
    { 
        k = scene(cam+dir*t);
        t += k.x;
        if (k.x < .001)
            break;
        if (k.x > 10.)
        {
            k.y = -1.;
            break;
        }
    }
    vec3 h = cam+dir*t;
    vec2 o = vec2(.001, 0);
    vec3 n = normalize(vec3(
        scene(h+o.xyy).x-scene(h-o.xyy).x,
        scene(h+o.yxy).x-scene(h-o.yxy).x,
        scene(h+o.yyx).x-scene(h-o.yyx).x
    ));
    float mat = k.y;


    vec4 colors[6]=vec4[](
        vec4(1,0,0,0),
        vec4(1,1,0,0),
        vec4(0,1,0,0),
        vec4(1,1,1,0),
        vec4(0,0,1,0),
        vec4(1,.5,0,0)
    );
    if (mat == 0.)
    {
        float fresnel = pow(1.-dot(-dir,n),5.);
        fresnel = mix(.0016,.1,fresnel);
        out_color = vec4(fresnel);
    }
    else if (mat == -1.)
    {
        uv *= 1.-length(uv)*.2;
        vec2 c = floor(uv*10.+iTime);
        vec2 u = fract(uv*10.+iTime)-.5;
        int colorIndex = int(hash2(c+.1*floor(iTime*SPEED))*6.);
        float d = sdRoundBox(vec3(u,0),vec3(.46),.05);
        float mask = smoothstep(.0,.01,-d);
        float vignette = smoothstep(1.,.3,length(uv)) * .7;
        out_color = colors[colorIndex] * mask * vignette;
    }
    else
    {
        mat = mod(mat,6.);
        // rewritten for shadertoy so it's less awful
        mat += (step(.1,n.x)+0.)*float(abs(n.x)>.1);
        mat += (step(.1,n.y)+2.)*float(abs(n.y)>.1);
        mat += (step(.1,n.z)+4.)*float(abs(n.z)>.1);
        out_color = colors[int(mod(mat,6.))];
    }

    out_color.rgb = pow(out_color.rgb, vec3(.4545));
    out_color.rgb = pow(out_color.rgb, vec3(1.2,1.1,1.0));
}