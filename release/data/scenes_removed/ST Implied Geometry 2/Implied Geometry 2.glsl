// https://www.shadertoy.com/view/MlcfW7

// Fork of "[twitch] Implied Geometry" by yx. https://shadertoy.com/view/llcfW7
// 2018-10-17 22:45:21

#define CHROMA

#define pi acos(-1.)
#define tau (pi*2.)

const float SCROLL_SPEED = .3;
const float SPIN_SPEED_H = 1.;
const float SPIN_SPEED_V = .5;
const float WIRE_THICKNESS = .05;
const float CUBE_SCALE = .66;
const float SLOW_DOWN = 2.3;
const float CAMERA_DELAY = 0.16;
const float CROMA = 0.02;

float time;
bool state;

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

vec3 slerp(vec3 p0, vec3 p1, float t)
{
    float om = acos(dot(normalize(p0), normalize(p1)));
    return (p0*sin((1.0-t)*om) + p1*sin(t*om)) / sin(om);
}

float sdOctahedron(vec3 p, float r)
{
    p = abs(p);
    float d = p.x + p.y + p.z - r;
    return d / sqrt(3.);
}

float sdLine(vec3 p, vec3 a, vec3 b)
{
    float t = dot(p-a,b-a)/dot(b-a,b-a);
    return distance(p,mix(a,b,t));
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    return sdLine(p,a,b)-r;
}

float sdCappedLine(vec3 p, vec3 a, vec3 b)
{
    float t = dot(p-a,b-a)/dot(b-a,b-a);
    t = clamp(t,0.,1.);
    return distance(p,mix(a,b,t));
}

float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    return sdCappedLine(p,a,b)-r;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdBox(vec3 p, vec3 r)
{
    vec3 d = abs(p)-r;
    return min(max(max(d.x,d.y),d.z),0.) + length(max(d,0.));
}

vec3 spin(vec3 p)
{
    p.xy = rotate(p.xy, time);
    p.yz = rotate(p.yz, time);
    p.zx = rotate(p.zx, time);
    return p;
}

vec3 spin2(vec3 p)
{
    p.xy = rotate(p.xy, -time);
    p.yz = rotate(p.yz, -time);
    p.zx = rotate(p.zx, -time);
    return p;
}

float scene(vec3 p)
{
    float d;
    if (state)
    {
        d = min(
            min(
                sdOctahedron(spin2(p), .5),
                min(
                	sdCappedCylinder(abs(spin(p)),vec3(1,0,0),vec3(0,1,0),WIRE_THICKNESS),
                    sdCappedCylinder(abs(spin2(p)),vec3(2,0,0),vec3(0,2,0),WIRE_THICKNESS)
                )
            ),
            min(
                min(
                	sdCappedCylinder(abs(spin(p)),vec3(0,1,0),vec3(0,0,1),WIRE_THICKNESS),
                	sdCappedCylinder(abs(spin(p)),vec3(0,0,1),vec3(1,0,0),WIRE_THICKNESS)
                    ),
                min(
                    sdCappedCylinder(abs(spin2(p)),vec3(0,2,0),vec3(0,0,2),WIRE_THICKNESS),
                	sdCappedCylinder(abs(spin2(p)),vec3(0,0,2),vec3(2,0,0),WIRE_THICKNESS)
                )
            )
        );
    }
    else
    {
        d = min(
            min(
                sdBox(spin2(p), vec3(.5)*CUBE_SCALE),
                min(
                	sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(0,1,1)*CUBE_SCALE,WIRE_THICKNESS),
                    sdCappedCylinder(abs(spin2(p)),vec3(2,2,2)*CUBE_SCALE,vec3(0,2,2)*CUBE_SCALE,WIRE_THICKNESS)
                    )
            ),
            min(
                min(
                	sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(1,0,1)*CUBE_SCALE,WIRE_THICKNESS),
                	sdCappedCylinder(abs(spin(p)),vec3(1,1,1)*CUBE_SCALE,vec3(1,1,0)*CUBE_SCALE,WIRE_THICKNESS)
                    ),
                min(
                    sdCappedCylinder(abs(spin2(p)),vec3(2,2,2)*CUBE_SCALE,vec3(2,0,2)*CUBE_SCALE,WIRE_THICKNESS),
                	sdCappedCylinder(abs(spin2(p)),vec3(2,2,2)*CUBE_SCALE,vec3(2,2,0)*CUBE_SCALE,WIRE_THICKNESS)
                )
            )
        );
    }
    return min(
        d,
        -sdSphere(p, 6.)
    );
}

void mainImage(out vec4 out_color, vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy - .5;
    uv.x *= iResolution.x / iResolution.y;
	
    time = iTime + CROMA * texelFetch(iChannel0, ivec2(fragCoord+iTime)%8, 0).x;
    
    for(int c=0;c<3;++c)
    {
        time += CROMA;
        
        float spinHTime = time * SPIN_SPEED_H;
        float spinVTime = time * SPIN_SPEED_V;
        float scrollTime = time * SCROLL_SPEED;
        
        vec3 perspcam = vec3(0,0,-2);
        vec3 perspdir = normalize(vec3(uv,.8));

        vec3 orthocam = vec3(uv*3.,-5.);
        vec3 orthodir = vec3(0,0,1);

        vec2 spinVang = sin(spinVTime - vec2(0, CAMERA_DELAY));
        spinVang = sign(spinVang) * pow(abs(spinVang), vec2(SLOW_DOWN));
        
        vec3 cam = mix(orthocam, perspcam, abs(spinVang.x));
        vec3 dir = mix(orthodir, perspdir, abs(spinVang.x));

        cam.yz = rotate(cam.yz, spinVang.x*.9);
        dir.yz = rotate(dir.yz, spinVang.y*.9);

        float shakeHtime = time + 0.1 * pow(cos(2.1*time), 4.);
        vec2 shakeHang = sin(shakeHtime - vec2(0, CAMERA_DELAY));
        
        cam.xz = rotate(cam.xz, spinHTime + shakeHang.x);
        dir.xz = rotate(dir.xz, spinHTime + shakeHang.y);

        state = dir.y > 0.;

        float m, t = 0.3;
        for(int i=0;i<50;++i)
        {
            t += m = scene(cam+dir*t);
            if(m < 0.01)break;
        }
        vec3 h = cam+dir*t;

        float th = 4.0 / iResolution.x;
        out_color[c] = smoothstep(-th, th, sin(tau*h.y-scrollTime));
    }
}