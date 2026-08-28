uniform float time, bassTime, bass, CC[4];
varying vec2 v;

/*
	SB Kaleidoscope Glow v1.0
	ported from GLSLSandbox by MK2k https://mk2k.net
	GLSLSandbox URL: http://glslsandbox.com/e#49619.1 (2018-10-30)
	Original Author: unknown

	-- Port Notes --
	time and bassTime are influencing the movement
*/

// #ifdef GL_ES
// precision mediump float;
// #endif

// #extension GL_OES_standard_derivatives : enable

//uniform float time;
//uniform vec2 mouse;
//uniform vec2 resolution;

void main( void ){
	vec3 color;
	float len;
	float t = (time + bassTime) * 2.;

	for(int i=0;i<3;i++) {
		//vec2 uv = gl_FragCoord.xy/resolution;
		vec2 uv = (v + 1.) * .5;
		
		vec2 offset = uv;
		offset-=.5;

		// unsquash circle
		// offset.x*=resolution.x/resolution.y;
		offset.x *= 1920. / 1080.;
		len=length(offset);
		
		t+=0.07;
		
		vec2 offset_unit_vector = offset/len;
		float firstMod = sin(t)+1.0;
		float secondMod = abs(sin(len*9.0-t*2.0));
		// uv += offset_unit_vector * firstMod * secondMod + mouse*2.;
		uv += offset_unit_vector * firstMod * secondMod;
		
		color[i]= .01 / length( abs(fract(uv)-.5) );
	}

	gl_FragColor=vec4(color/len,time);
}