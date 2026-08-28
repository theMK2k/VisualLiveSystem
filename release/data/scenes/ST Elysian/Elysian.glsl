varying vec2 v;
uniform float time, bassTime, bass, CC[4];
uniform sampler2D rnd, tex, tule;

uniform sampler2D iChannel0;

// https://www.shadertoy.com/view/4lyyzh
// https://gist.github.com/willkirkby/dcad2f53b0ce381c30513f707786dbb4

/*
	ST Elysian v1.0
	ported from ShaderToy by MK2k https://mk2k.net
	ShaderToy URL:   https://www.shadertoy.com/view/4lyyzh (2018-11-22)
	GLSL Github URL: https://gist.github.com/willkirkby/dcad2f53b0ce381c30513f707786dbb4
	Original Author: https://www.shadertoy.com/user/yx

	-- Port Notes --
	Camera Movement is influenced by bassTime
	White bars' visibility is influenced by bass
*/

#define pi acos(-1.)

vec2 modang(vec2 p, float rep)
{
  float r = length(p);

  float ang = atan(p.x,p.y) / (2.0 * pi);
  ang = (fract(ang*rep)+1.0)/rep;
  ang *= 2.0*pi;

  return vec2(sin(ang),cos(ang))*r;
}

float sdBox( vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 color(vec2 uv)
{
	float runTime = time + bassTime;

  uv = fract(uv);
  uv = uv * 1.04 - .02;
  if(any(greaterThan(abs(uv-.5),vec2(.5))))
    return vec3(0.0);

  vec2 originalUv = uv;

  uv = fract(uv * 8.0);
  uv = uv * 1.1 - .05;
  if(any(greaterThan(abs(uv-.5),vec2(.5))))
    return vec3(0.0);
  
  float d = sdBox(fract(uv*4.0)-.5, vec2(.2));
  float threshold = .04;
  //threshold = max(length(dFdx(uv)),length(dFdy(uv)));
  float mask = smoothstep(threshold,-threshold,d);
  //mix(vec3(66, 244, 226), vec3(65, 68, 244), sin(uv.x+iTime*4.)*.5+.5) / 255;
  uv = fract(originalUv);
  uv *= 8.0 * 4.0;
  uv = floor(uv);
  uv /= 8.0 * 4.0;
  vec3 col = vec3(.03*bass);
  col += smoothstep(.6,1.,sin(uv.x*20.-runTime*1.5))*(CC[1]*bass+CC[0]);	// white bars
  col += smoothstep(.9,1.,sin(3.*atan(uv.x-.5,uv.y-.5)-runTime*1.5+.5)) * vec3(.2,.6,1.0);	// blue bars
  col += smoothstep(.9,1.,sin(3.*atan(uv.x-.5,uv.y-.5)+runTime*1.5+.5)) * vec3(1.0,.5,.2);	// red bars
	//mask=bass;
  return vec3(mask) * col;
}

vec3 pal(vec3 a, vec3 b, vec3 c, vec3 d, float t)
{
  return a+b*cos(2.0*pi*(c*t+d));
}

vec3 logichroma(float t)
{
  return pal(
    vec3(.5),
    vec3(.5),
    vec3(1.),
    vec3(0.0,1.0,2.0)/3.0,
    t
  );
}

void main(void)
{
	float runTime = (time + bassTime)*8.;
	vec2 resolution = vec2(1920., 1080.);
	
	vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.3333;
  uv /= vec2(resolution.y / resolution.x, 1.0);
  uv.y += .07;

  gl_FragColor = vec4(color(gl_FragCoord.xy / resolution.xy), 1.0);
  
  float chromaStrength = sin(runTime*.5);	// if chromaStrenght = 0 we get the pixelated view

  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for(int i=0;i<100;++i)
  {
    uv *= mix(1.,.996,chromaStrength);
    vec2 u = modang(uv, 3.0);
    u = vec2(
      u.x/u.y,
      1./u.y
    ) / sqrt(3.0)*.5 + .5;
    
    vec3 col = color(u+vec2(0.0,-runTime*.2));
    float depthfog = pow(smoothstep(3.,-1.,-u.y),2.);
    gl_FragColor += vec4(col * depthfog * logichroma(float(i)/100.0), 1.0);
  }
  gl_FragColor.rgb /= 4.0;
}
