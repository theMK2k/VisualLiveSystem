varying vec2 v;
uniform float time, bassTime, bass, CC[4];
uniform sampler2D rnd, tex, tule;

uniform sampler2D iChannel0;

/*
	ST Geometric Descent v1.0
	ported from ShaderToy by MK2k https://mk2k.net
	ShaderToy URL:   https://www.shadertoy.com/view/XtGfRG (2018-11-22)
	Original Author: https://www.shadertoy.com/user/yx

	-- Port Notes --
	Camera Movement is influenced by bassTime
	Some objects' size is influenced by bass
*/

// 

const float phi = 1.618033988749895;

float noise(vec3 p)
{
    return fract(
        sin(
            dot(p, vec3(12.4536728,432.45673828,32.473682))
        )*43762.342);
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

float sdIcosahedron(vec3 p, float r)
{
    const float q = 2.618033988749895;

    const vec3 n1 = vec3(0.934172358962716, 0.356822089773090, 0.0);
    const vec3 n2 = vec3(0.577350269189626);

    p = abs(p/r);
    float a = dot(p, n1.xyz);
    float b = dot(p, n1.zxy);
    float c = dot(p, n1.yzx);
    float d = dot(p, n2.xyz)-n1.x;
    return max(max(max(a,b),c)-n1.x,d)/r; // turn into (...)/r  for weird refractive effects when you subtract this shape
}

float sdDodecahedron(vec3 p, float r)
{
    const vec3 n = vec3(0.850650808352040, 0.525731112119134, 0.0);

    p = abs(p/r);
    float a = dot(p,n.xyz);
    float b = dot(p,n.zxy);
    float c = dot(p,n.yzx);
    return (max(max(a,b),c)-n.x)*r;
}

float scene(vec3 p)
{
    float runTime = 2.*time + 2.*bassTime;

		p.xy = rotate(p.xy, p.z*.05);

    float n = noise(floor((p)/4.));
    float shape = fract((floor(p.x/4.)+floor(p.y/4.)*2.)/4.);
    float spinOffset1 = floor(p.z/4.);
    float spinOffset2 = floor(p.z/4.+2.);
    float spinOffset3 = floor(p.z/4.+4.);


    p = mod(p,4.)-2.;
    p.xy = rotate(p.xy, runTime+spinOffset1);
    p.yz = rotate(p.yz, runTime+spinOffset2);
    p.zx = rotate(p.zx, runTime+spinOffset3);

    if (shape < .25) {
        return min(
            sdDodecahedron(p,2.*(bass*CC[1]+CC[0])),
            sdIcosahedron(p.zyx,2.*(bass*CC[1]+CC[0]))
        );	// *(1.-bass)
    } else if (shape < .5) {
        return max(
            sdDodecahedron(p,1.),
            -sdIcosahedron(p.zyx,.9)
        );
    } else if (shape < .75) {
        return max(
            -sdDodecahedron(p,.95),
            sdIcosahedron(p.zyx,1.)
        );
    } else {
        return max(
            sdDodecahedron(p,.95),
            sdIcosahedron(p.zyx,1.)
        );
    }
}

void mainImage(out vec4 out_color, vec2 fragCoord)
{
    float runTime = 2.*time + 2.*bassTime;
		vec2 resolution = vec2(1920., 1080.);
		
		vec2 uv = fragCoord.xy / resolution.xy -.3333;
    uv.x *= resolution.x / resolution.y;

    uv *= 1.+length(uv)*.5;

    vec3 cam = vec3(0,0,0);
    vec3 dir = normalize(vec3(uv,1));

    //cam.yz = rotate(cam.yz, .3);
    //dir.yz = rotate(dir.yz, .3);

    cam.z = runTime * 4.;
    dir.xy = rotate(dir.xy, runTime*.1);
    //dir.yz = rotate(dir.yz, iTime*.3);
    //dir.zx = rotate(dir.zx, iTime*.3);

    float t = 0.1;
    float k = 0.1;
    int i;
    for(i=0;i<100;++i)
    {
        k = scene(cam+dir*t)*.55;
        t += k;
        if (k < .001) break;
    }

    vec3 h = cam+dir*t;
    vec2 o = vec2(.001, 0);
    vec3 n = normalize(vec3(
        scene(h+o.xyy)-scene(h-o.xyy),
        scene(h+o.yxy)-scene(h-o.yxy),
        scene(h+o.yyx)-scene(h-o.yyx)
    ));

    float iterFog = pow(1.-(float(i)/100.), 2.);
    float light = pow(max(0.,n.x*.5+.5),2.);
    float vignette = smoothstep(2.,0.,length(uv));
    vec3 a = mix(vec3(.01,.01,.1),vec3(0,1,1),iterFog);
    vec3 b = mix(vec3(0,0,0),vec3(1,sin(runTime*.4)*.5+.5,cos(runTime*.4)*.5+.5),light*iterFog*4.);
    out_color = vec4(a + b, 1);
    out_color *= vignette;
}

// This is hidden from Shadertoy
void main() {
	mainImage(gl_FragColor,gl_FragCoord.xy);
}
