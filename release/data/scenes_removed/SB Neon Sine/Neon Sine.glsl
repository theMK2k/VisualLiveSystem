// http://glslsandbox.com/e#49824.1

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;

uniform vec2 resolution;

// pervert
#define PI 90

void main( void ) {

	// I just added a couple of other variations and explanations for myself. 
	
	// center pixel 
	vec2 p = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
	
	// let's play with time 
	float t = 0.9;
	
	float sx = 0.3 * (p.x + 0.8) * sin( 11.0 * p.x - 1. * pow(time*t, 0.9)*6.);
	

		
	// separating out so we can comment out sections. This is probably a performance hit
	float dy;
 	
	// sine wave 
	dy += 4./ ( 123. * abs(p.y - sx));
	
	// horiz line 
	dy += 1./ (160. * length(p - vec2(p.x, 0)));
	
	// moving horiz sin guide line 
	dy += 1./ (160. * length(p - vec2(p.x, 0.2*sin(time*t))));
	
        // vert line 
	dy += 1./ (160. * length(0.- vec2(p.x, 0)));
	
	// full screen flash 
	
	dy += 1./ (160. * length(0. - vec2(0., sin(time*t))));
	
	// blinking vert line???
	
	dy += 1./ (160. * length(0. - vec2(p.x, 0.2*sin(time*t))));
	

	
	gl_FragColor = vec4( (p.x + 0.2) * dy, 0.3 * dy, dy, 2.1 );

}