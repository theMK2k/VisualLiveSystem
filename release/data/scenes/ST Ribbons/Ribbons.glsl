varying vec2 v;
uniform float time, bassTime, bass, CC[4];
uniform sampler2D rnd, tex, tule;
uniform sampler1D spectrum;

/*
	ST Ribbons v1.0
	ported from ShaderToy by MK2k https://mk2k.net
	ShaderToy URL:   https://www.shadertoy.com/view/lds3zr (2018-11-23)
	Original Author: https://www.shadertoy.com/user/XT95

	-- Port Notes --
	Camera shake is influenced by bass
	ribbon flashing is influenced by spectrum (bass, mid-range, upper-mid-range, high-end) and modifiers CC[0] (offset) and CC[1] (intensity)
*/

//-----------------------------------------------------------------------------
// Utils
//-----------------------------------------------------------------------------
#define t (time+bassTime)*2.

vec3 rotateY(vec3 myVec, float x)
{
    return vec3(
        cos(x)*myVec.x - sin(x)*myVec.z,
        myVec.y,
        sin(x)*myVec.x + cos(x)*myVec.z
    );
}

vec3 rotateX(vec3 myVec, float x)
{
    return vec3(
        myVec.x,
        myVec.y*cos(x) - myVec.z*sin(x),
        myVec.y*sin(x) + myVec.z*cos(x)
    );
}

vec3 rotateZ(vec3 myVec, float x)
{
    return vec3(
        myVec.x*cos(x) - myVec.y*sin(x),
        myVec.x*sin(x) + myVec.y*cos(x),
        myVec.z
    );
}
//-----------------------------------------------------------------------------
// Scene/Objects
//-----------------------------------------------------------------------------
float box(vec3 p, vec3 pos, vec3 size)
{
	return max(max(abs(p.x-pos.x)-size.x,abs(p.y-pos.y)-size.y),abs(p.z-pos.z)-size.z);
}


float ribbon1(vec3 p)
{
	return box(p,vec3(cos(p.z)*.5,sin(p.z+p.x)*.5,.0),vec3(.02,0.02,3.5+t));
}
float ribbon2(vec3 p)
{
	return box(p,vec3(cos(p.z+1.5+p.x)*.6,sin(p.z+1.)*.3,.0),vec3(.02,0.02,3.+t));
}
float ribbon3(vec3 p)
{
	return box(p,vec3(sin(p.z+p.y)*.4,cos(p.z+p.x)*.5,.0),vec3(.02,0.02,4.+t));
}
float ribbon4(vec3 p)
{
	return box(p,vec3(sin(p.z+1.5+p.x)*.5,cos(p.z+1.5)*.6,.0),vec3(.02,0.02,2.+t));
}
float scene(vec3 p)
{
	float d = .5-abs(p.y);
	d = min(d, ribbon1(p) );
	d = min(d, ribbon2(p) );
	d = min(d, ribbon3(p) );
	d = min(d, ribbon4(p) );
	
	return d;
}

//-----------------------------------------------------------------------------
// Raymarching tools
//-----------------------------------------------------------------------------
//Raymarche by distance field
vec3 Raymarche(vec3 org, vec3 dir, int step)
{
	float d=0.0;
	vec3 p=org;
	
	for(int i=0; i<64; i++)
	{
		d = scene(p);
		p += d * dir;
	}
	
	return p;
}
//get Normal
vec3 getN(vec3 p)
{
	vec3 eps = vec3(0.01,0.0,0.0);
	return normalize(vec3(
		scene(p+eps.xyy)-scene(p-eps.xyy),
		scene(p+eps.yxy)-scene(p-eps.yxy),
		scene(p+eps.yyx)-scene(p-eps.yyx)
	));
}

//Ambiant Occlusion
float AO(vec3 p, vec3 n)
{
	float dlt = 0.1;
	float oc = 0.0, d = 1.0;
	for(int i = 0; i<6; i++)
	{
		oc += (float(i) * dlt - scene(p + n * float(i) * dlt)) / d;
		d *= 2.0;
	}
	return clamp(1.0 - oc, 0.0, 1.0);
}

//-----------------------------------------------------------------------------
// Main Loop
//-----------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 resolution = vec2(1920., 1080.);
	
	vec4 color = vec4(0.0);
	
	// http://decibelcar.com/articles/43-theory-and-physics/141-treble-hertz.html
	// Bass (Approximately 20hz-140hz)
	// Mid-Bass (Approximately 140hz-400hz)

	//float bass = texture( iChannel0, vec2(20./256.,0.25) ).x*.75+texture( iChannel0, vec2(50./256.,0.25) ).x*.25;
	float bassTex = 0.;
	int bassRange = 5;
	for (int i = 0; i < 0+bassRange; i++) {
		bassTex += texture1D( spectrum, float(i)/256.0).x * 2.0; //*(bassRange-i);
	}

	// Midrange (Approximately 400hz-2.6khz)
	float midTex = 0.;
	int midRange = 28;
	for (int i = 0+bassRange; i < 0+bassRange+midRange; i++) {
		midTex += texture1D( spectrum, float(i)/256.0).x * 2.0;	//*(midRange-i);
	}

	// Upper Midrange (Approximately 2.6khz-5.2khz)
	float uppermidTex = 0.;
	int uppermidRange = 20;
	for (int i = 0+bassRange+midRange; i < 0+bassRange+midRange+uppermidRange; i++) {
		uppermidTex += texture1D( spectrum, float(i)/256.0).x * 6.0; //*(uppermidRange-i);
	}

	// High End (Approximately 5.2khz-20khz - Two Regions)
	float highendTex = 0.;
	int highendRange = 40;
	for (int i = 0+bassRange+midRange+uppermidRange; i < 0+bassRange+midRange+uppermidRange+highendRange; i++) {
		highendTex += texture1D( spectrum, float(i)/256.0).x * 4.0;	//*(highendRange-i)
	}

	//texture1D( spectrum, 20./256.).x*.75+texture1D( spectrum, 50./256.).x*.25;
	
	//vec2 uv = -1.0 + 2.0 * fragCoord.xy / resolution;
	//uv.x *= resolution.x/resolution.y;
	vec2 uv = v;
	
	//vec3 org = vec3(texture( iChannel0, vec2(1./256.,0.25) ).x*.2+1.,+0.3+bass*.05,t+5.);
	  vec3 org = vec3(1.-2.0*CC[2],+0.3+(bassTex*CC[1])*.05,t+5.);
	
	vec3 dir = normalize(vec3(uv.x-2.0*CC[2],-uv.y,2.));
	dir = rotateX(dir,.15);
	dir = rotateY(dir,2.8);
	
	vec3 p = Raymarche(org,dir,48);
	vec3 n = getN(p);


  color = vec4( max( dot(n.xy*-1.,normalize(p.xy-vec2(.0,-.1))),.0)*.01 );

	// orange ribbon (mid-range)
	//color += vec4(1.0,0.3,0.0,1.0)/(ribbon1(p-n*.01)*20.+.75)*pow(bass,2.)*3.;
	  color += vec4(1.0,0.3,0.0,1.0)/(ribbon1(p-n*.01)*20.+.75)*pow(CC[0]+midTex*CC[1], 2.)*3.0;

	// purple ribbon (upper mid-range)
	//color += vec4(0.5,0.3,0.7,1.0)/(ribbon2(p-n*.01)*20.+.75)*pow(texture( iChannel0, vec2(64./256.,0.25) ).x,2.)*2.;
	  color += vec4(0.5,0.3,0.7,1.0)/(ribbon2(p-n*.01)*20.+.75)*pow(CC[0]+uppermidTex*CC[1], 2.)*2.0;

	// blue ribbon (bass)
	//color += vec4(0.0,0.5,1.0,1.0)/(ribbon3(p-n*.01)*20.+.75)*pow(texture( iChannel0, vec2(128./256.,0.25) ).x,2.)*5.;
	  color += vec4(0.0,0.5,1.0,1.0)/(ribbon3(p-n*.01)*20.+.75)*pow(CC[0]+bassTex*CC[1],2.)*5.0;

	// green ribbon (high-end)
	//color += vec4(0.0,1.0,0.2,1.0)/(ribbon4(p-n*.01)*20.+.75)*pow(texture( iChannel0, vec2(200./256.,0.25) ).x,2.)*5.;
	  color += vec4(0.0,1.0,0.2,1.0)/(ribbon4(p-n*.01)*20.+.75)*pow(CC[0]+highendTex*CC[1],2.)*5.0;

	color *= AO(p,n);
	color = mix(color,vec4(0.),vec4((min(distance(org,p)*.05,1.0))));
	
	color.a = 1.0;
	
	fragColor = color;

}

// This is hidden from Shadertoy
void main() {
	mainImage(gl_FragColor,gl_FragCoord.xy);
}
