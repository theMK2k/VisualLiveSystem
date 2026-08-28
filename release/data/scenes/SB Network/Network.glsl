#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float time, bassTime, bass, CC[4];
varying vec2 v;

/*
	SB Network v1.0
	ported from GLSLSandbox by MK2k https://mk2k.net
	GLSLSandbox URL: http://glslsandbox.com/e#49793.0 (2018-10-30)
	Original Author: srtuss

	-- Port Notes --
	camera movement and flicker on the grid is modified by bassTime
	CC[0] (Offset) and CC[1] (Bass FX) control the visibility of the network
*/

// rotate position around axis
vec2 rotate(vec2 p, float a)
{
	return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

// 1D random numbers
float rand(float n)
{
    return fract(sin(n) * 43758.5453123);
}

// 2D random numbers
vec2 rand2(in vec2 p)
{
	return fract(vec2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
}

// 1D noise
float noise1(float p)
{
	float fl = floor(p);
	float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}

// voronoi distance noise, based on iq's articles
float voronoi(in vec2 x)
{
	vec2 p = floor(x);
	vec2 f = fract(x);
	
	vec2 res = vec2(8.0);
	for(int j = -1; j <= 1; j ++)
	{
		for(int i = -1; i <= 1; i ++)
		{
			vec2 b = vec2(i, j);
			vec2 r = vec2(b) - f + rand2(p + b);
			
			// chebyshev distance, one of many ways to do this
			float d = max(abs(r.x), abs(r.y));
			
			if(d < res.x)
			{
				res.y = res.x;
				res.x = d;
			}
			else if(d < res.y)
			{
				res.y = d;
			}
		}
	}
	return res.y - res.x;
}

void main()
{
  float runTime = (time + bassTime) * 4.;
	
	float flicker = noise1(runTime * 1.0) * 0.8 + 0.4;

  //vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec2 uv = (v + 2. )* .25;

	uv = (uv - 0.5) * 4.0;
	vec2 suv = uv;
	//uv.x *= resolution.x / resolution.y;
	uv.x *= 1920. / 1080.;
	
	float v0 = 0.0;
	
	// that looks highly interesting:
	v0 = 1.0 - length(uv) * 0.5;
	
	
	// a bit of camera movement
	uv *= 0.6 + sin(runTime * 0.1) * 0.4;
	uv = rotate(uv, sin(runTime * 0.3) * 1.0);
	uv += runTime * 0.4;
	
	
	// add some noise octaves
	float a = 0.6, f = 1.3;
	
	for(int i = 0; i < 4; i ++) // 4 octaves also look nice, its getting a bit slow though
	{	
		float v1 = voronoi(uv * f + 5.0);
		float v2 = 0.0;
		
		// make the moving electrons-effect for higher octaves
		if(i > 0)
		{
			// of course everything based on voronoi
			v2 = voronoi(uv * f * 0.5 + 50.0 + runTime);
			
			float va = 0.0, vb = 0.0;
			va = 1.0 - smoothstep(0.0, 0.1, v1); // MK2k: + bass is possible
			vb = 1.0 - smoothstep(0.0, 0.08, v2);
			v0 += a * pow(va * (0.5 + vb), 2.0);
		}
		
		
		// make sharp edges
		v1 = 1.0 - smoothstep(0.0, 0.3, v1);
		
		// noise is used as intensity map
		v2 = a * (noise1(v1 * 5.5 + 0.1));
		
		// octave 0's intensity changes a bit
		if(i == 0)
			v0 += v2 * flicker;
		else
			v0 += v2;
		
		f *= 3.0;
		a *= 0.0 + 0.7*CC[0] + 0.7*CC[1]*bass;
	}

	// slight vignetting
	v0 *= exp(-1.0 * length(suv)) * 1.2;
	
	vec3 cexp = vec3(2.0, 4.0, 1.0);
	cexp *= 1.4;
	
	// old blueish color set
	// vec3 cexp = vec3(6.0, 4.0, 2.0);
	
	vec3 col = vec3(pow(v0, cexp.x), pow(v0, cexp.y), pow(v0, cexp.z)) * 2.0;
	
	gl_FragColor = vec4(min(col,vec3(1.0)), 1.0);
}