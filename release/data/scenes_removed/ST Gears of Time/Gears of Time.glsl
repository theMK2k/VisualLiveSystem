// https://www.shadertoy.com/view/XlyyDD

#define pi acos(-1.)
#define tau (pi*2.)

#define saturate(a) clamp(a,0.,1.)

float tooth(float x, float offset, float scale)
{
    return saturate((abs(x-.5)-offset)*scale)*.12;
}

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

vec3 pal(vec3 a, vec3 b, vec3 c, vec3 d, float t)
{
    return a+b*cos(tau*(c*t+d));
}

vec3 rainbow(float t)
{
    return pal(
        vec3(.5),
        vec3(.5),
        vec3(1),
        vec3(0,1,2)/3.,
        t
    );
}

vec4 plasma(vec2 uv)
{
    return vec4(rainbow(fract(atan(uv.x, uv.y) / tau)), 1);
}

float tick(float time)
{
    float t = saturate(fract(time)*3.);
    const float k = 2.;
    return (sin(mix(-k,k,t))/sin(k))*.5+.5;
}

const float DEPTH_EXPONENT = 1.15;
const float ATTENUATION = .2;
const float SPIRAL_RADIUS = .3;
const float FLIGHT_SPEED = 3.;
const float GEAR_THICKNESS = .2;
const float SPIRAL_PERIOD_SCALE = .4;

void mainImage(out vec4 out_color, vec2 fragCoord)
{
    vec2 screenUv = fragCoord.xy / iResolution.xy;

    vec2 baseUv = gl_FragCoord.xy / iResolution.xy - .5;
    baseUv.x *= iResolution.x / iResolution.y;
    baseUv *= .65;
    baseUv.y -= .05;

    out_color = vec4(1,0,0,1);

    for (int i = 20; i >= 0; --i)
    {
        vec2 uv = baseUv;
        vec2 uv2 = baseUv;
        float depth = float(i) - fract(iTime*FLIGHT_SPEED);
        float depth2 = depth + GEAR_THICKNESS;

        uv *= pow(DEPTH_EXPONENT, depth);
        uv2 *= pow(DEPTH_EXPONENT, depth2);

        uv -= vec2(
            sin(depth*SPIRAL_PERIOD_SCALE),
            cos(depth*SPIRAL_PERIOD_SCALE)-1.
        )*SPIRAL_RADIUS;
        uv2 -= vec2(
            sin(depth2*SPIRAL_PERIOD_SCALE),
            cos(depth2*SPIRAL_PERIOD_SCALE)-1.
        )*SPIRAL_RADIUS;

        vec2 uvWithoutRotation = uv;

        uv = rotate(uv, -tick(iTime+depth*.1) * (tau / 12.));

        float a = atan(uv.x, uv.y) / tau;
        float gear1 = (length(uv) - .8) + tooth(fract(a * 12.), .175, 8.);
        float gear2 = (length(uv) - .83) + tooth(fract(a * 12.), .23, 8.);
        float gear3 = (length(uv2) - .8) + tooth(fract(a * 12.), .175, 8.);

        vec4 color = vec4(0);
        if (gear1 > 0.)
        {
            color = mix(
                vec4(rainbow(depth*.1),1),
                vec4(rainbow(depth*.1)*.6,1),
                saturate(gear2*30.+.5)
            );
        }
        else if (gear3 > 0.)
        {
            color = vec4(rainbow(depth*.1)*.1,1);
        }
        color = saturate(color);

        out_color = mix(out_color, color, color.a) * pow(.997, depth*depth);
    }
    out_color = pow(out_color, vec4(.4));
}