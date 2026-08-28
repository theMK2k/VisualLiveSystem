uniform float time, bassTime, bass, CC[4];
varying vec2 v;

/*
	SB Starfield Universe v1.0
	ported from GLSLSandbox by MK2k https://mk2k.net
	GLSLSandbox URL: http://glslsandbox.com/e#49833.0 (2018-10-30)
	Original Author: unknown

	-- Port Notes --
	camera movement is modified by bassTime
	CC[0] (Offset) and CC[1] (Bass FX) control flicker on certain hotspots

	TODO: a few seconds in, the layers shift too much and star field creeps in the corners
*/

// #ifdef GL_ES
// precision mediump float;
// #endif

// #extension GL_OES_standard_derivatives : enable

// uniform float time;
// uniform vec2 resolution;

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}
float field(in vec3 p,float s, float runTime) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(runTime) * 4373.11));
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
float field2(in vec3 p, float s, float runTime) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(runTime) * 4373.11));
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


void main( ) {

	float runTime = (time + bassTime);

	vec2 resolution = vec2(1920., 1080.);

  vec2 uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;
	vec2 uvs = uv * resolution.xy / max(resolution.x, resolution.y);
	vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
	p += .2 * vec3(sin(runTime / 160.), sin(runTime / 120.),  sin(runTime / 1280.));
	
	float freqs[4];
	//Sound
	freqs[0] = noise(vec3( 0.01*100.0, 0.25 ,runTime/10.0) );
	freqs[1] = noise(vec3( 0.07*100.0 + (CC[0] + bass)*10.*CC[1], 0.25 ,runTime/10.0) );
	freqs[2] = noise(vec3( 0.15*100.0, 0.25 ,runTime/10.0) );
	freqs[3] = noise(vec3( 0.30*100.0, 0.25 ,runTime/10.0) );

	float t = field(p,freqs[2], runTime);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	
    //Second Layer
	vec3 p2 = vec3(uvs / (4.+sin(runTime*0.11)*0.2+0.2+sin(runTime*0.15)*0.3+0.4), 1.5) + vec3(2., -1.3, -1.);
	p2 += 0.2 * vec3(sin(runTime / 16.), sin(runTime / 12.),  sin(runTime / 128.));
	float t2 = field2(p2,freqs[3], runTime);
	vec4 c2 = mix(.4, 1., v) * vec4(1.3 * t2 * t2 * t2 ,1.8  * t2 * t2 , t2* freqs[0], t2);
	
	
	//Let's add some stars
	//Thanks to http://glsl.heroku.com/e#6904.0
	vec2 seed = p.xy * 2.0;	
	seed = floor(seed * resolution.x);
	vec3 rnd = nrand3( seed );
	vec4 starcolor = vec4(pow(rnd.y,40.0));
	
	//Second Layer
	vec2 seed2 = p2.xy * 2.0;
	seed2 = floor(seed2 * resolution.x);
	vec3 rnd2 = nrand3( seed2 );
	starcolor += vec4(pow(rnd2.y,40.0));
	
	gl_FragColor = mix(freqs[3]-.3, 1., v) * vec4(1.5*freqs[2] * t * t* t , 1.2*freqs[1] * t * t, freqs[3]*t, 1.0)+c2+starcolor;
}