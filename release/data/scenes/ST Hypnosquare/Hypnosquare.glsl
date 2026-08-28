uniform float time, bassTime, bass, CC[4];
varying vec2 v;
uniform sampler2D iChannel0;

/*
	ST Hypnosquare v1.0
	ported from ShaderToy by MK2k https://mk2k.net
	ShaderToy URL:   https://www.shadertoy.com/view/lscczM (2018-10-30)
	Original Author: https://www.shadertoy.com/user/104

	-- Port Notes --
	Camera Movement is influenced by bassTime
*/

void mainImage(out vec4 o, vec2 O)
{
    vec2 resolution = vec2(1920., 1080.);
		
		float t = -1.0*(time + bassTime),a=t*.05,s=sin(a),c=cos(a);
    vec2 R = resolution.xy,
        V=(O-.5*R)/R.y*5.*mat2(c,s,-s,c)
        ,N=O/R-.5;
    o-=o-
        .3-fract(t+sin(t)+abs(vec4(N,-N)*.2+V.x)+abs(V.y))
        +.1*fract(sin(dot(R+t,N))*1e5)+dot(N,N*3.)
        ;
}

// This is hidden from Shadertoy
void main() {
	mainImage(gl_FragColor,gl_FragCoord.xy);
}
