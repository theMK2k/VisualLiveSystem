uniform float time, bassTime, bass, CC[4];
varying vec2 v;

/*
	SB Twisted Colorwheel v1.0
	ported from GLSLSandbox by MK2k https://mk2k.net
	GLSLSandbox URL: http://glslsandbox.com/e#49825.0 (2018-10-30)
	Original Author: unknown

	-- Port Notes --
	movement is modified by bass and CC[1] (bass FX)
	bassTime is also modifying time
*/

// #ifdef GL_ES
// precision mediump float;
// #endif

// uniform float time;
// uniform vec2 mouse;
// uniform vec2 resolution;

void main()
{
	vec2 resolution = vec2(1920., 1080.);
	
	float t;
	t = (time + bassTime) * 3.0;
	
	vec2 r = resolution,
	
	o = gl_FragCoord.xy - r/3.; // *(sin(time)+.5)

	o = vec2(length(o) / r.y - .3, atan(o.y,o.x));	//  + .3*bass*CC[1]

	vec4 s = 0.07*cos(1.5*vec4(0.0+bass*CC[1],1.0+bass*CC[1],2.0+bass*CC[1],3.0+bass*CC[1]) + t + o.y + cos(o.y) * cos(t)),
	e = s.yzwx,
	f = max(o.x-s,e-o.x);

	gl_FragColor = dot(clamp(f*r.y,0.,1.), 72.*(s-e)) * (s-.1) + f*bass*CC[1];
}
