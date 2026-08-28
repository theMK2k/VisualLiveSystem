// Created by anatole duprat - XT95/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

varying vec2 v;
uniform float time,bass,bassTime,CC[4];
uniform sampler2D tex;
//Maths
const float PI = 3.14159265;


	void skyInit();
	vec3 skyProcedural( in vec3 origin, in vec3 direction );
	
	float daytime=6.;
	vec3 sunDirection = vec3(0.0);
	vec3 sunColor = vec3(0.0);


mat3 rotate( in vec3 v, in float angle)
{
	float c = cos(radians(angle));
	float s = sin(radians(angle));
	
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

mat3 lookat( in vec3 fw, in vec3 up )
{
	fw = normalize(fw);
	vec3 rt = normalize( cross(fw, normalize(up)) );
	return mat3( rt, cross(rt, fw), fw );
}


//Raymarching 
float map( in vec3 p );

float box( in vec3 p, in vec3 data )
{
    return max(max(abs(p.x)-data.x,abs(p.y)-data.y),abs(p.z)-data.z);
}

float sphere( in vec3 p, in float size)
{
	return length(p)-size;
}

vec4 raymarche( in vec3 org, in vec3 dir, in vec2 nfplane )
{
	float d = 1.0, g = 0.0, t = 0.0;
	vec3 p = org+dir*nfplane.x;
	
	for(int i=0; i<64; i++)
	{
		if( d > 0.001 && t < nfplane.y )
		{
			d = map(p);
			t += d;
			p += d * dir;
			g += 1./42.;
		}
	}
	
	return vec4(p,g);
}

vec3 normal( in vec3 p )
{
	vec3 eps = vec3(0.01, 0.0, 0.0);
	return normalize( vec3(
		map(p+eps.xyy)-map(p-eps.xyy),
		map(p+eps.yxy)-map(p-eps.yxy),
		map(p+eps.yyx)-map(p-eps.yyx)
	) );
}

float ambiantOcclusion( in vec3 p, in vec3 n, in float d )
{
    float dlt = 0.0;
    float oc = 0.0;
    
    for(int i=1; i<=6; i++)
    {
		dlt = d*float(i)/6.;
		oc += (dlt - map(p+n*dlt))/exp(dlt);
    }
    oc /= 6.;
    
    return clamp(pow(1.-oc,d), 0.0, 1.0);
}



float fnoise( in vec3 p )
{
    vec3 i = floor(p);
    vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
    vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
    a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
    a.xy = mix(a.xz, a.yw, f.y);
    return mix(a.x, a.y, f.z);
}

//Geometry
float ill = 0.;
float impulsTime = (-time*.1+bassTime*10.);
float map( in vec3 p )
{
	float d = p.y+1.;
	vec3 pp = p;
	ill = 0.;
	
	//mirrors
	p = abs(p);
	p = rotate(vec3(-1.,0.,0.),40.)*p;
	p = abs(p);
	p = rotate(vec3(0.,1.,0.),45.)*p;
	p = abs(p);
	
	//make a branch of cubes
	for(int i=0; i<15; i++)
	{
		p -= vec3(.25);
		p = rotate( normalize( vec3(.5, .25, 1.0 ) ), 20.+pp.x+pp.y+pp.z + cos(time)*2.+sin(time*.7156) )*p;
		
		
		float size = cos(float(i)/20.*PI*2.-impulsTime);
		float dbox = box( p, vec3( (1.1-float(i)/20.)*.25 + pow(size*.4+.4,10.) ) );
	
		if( dbox < d)
		{
			d = dbox;
			ill = pow(size*.5+.5, 10.);
		}
	
	}
	//add another one iteration with a sphere
	p -= vec3(.25);
	p = rotate( normalize( vec3(.5, .25, 1.0 ) ), 20.+pp.x+pp.y+pp.z )*p;
	d = min(d, sphere(p,.25) );
	
	return d;
}

//Shading
vec4 shade( in vec4 p, in vec3 n, in vec3 org, in vec3 dir )
{		
	//direct lighting
	vec4 col = vec4(.15);
	col += pow(vec4(sunColor,1.)*max( dot(n, sunDirection), 0.)*.15, vec4(1.));
	
	//illumination of the tree
	col += mix( vec4(1.,.3,.1,1.), vec4(.1, .7, .1,1.), length(p.xyz)/8.)*ill*p.w*(2.+bass);

	/*float roots = clamp( length(p)*4.-23., 0., 1.)*bass;
	col += vec4(.7,.7+cos(p.x+p.y+p.z)*.3,1.,1.)*roots;*/
	if(p.y+1.<.05)
		col = texture2D(tex, p.xz*.2)*.4;
		
	//ao
	col *= pow( ambiantOcclusion(p.xyz,n,1.) , 1.5 );
	
	//fog/sky
	col = mix(col, vec4(skyProcedural(org,dir),1.)*.75, vec4(1.)*min( pow( distance(p.xyz,org)/20., 2. ), 1. ) );
	
	return vec4(col.rgb,ill*(1.-min( pow( distance(p.xyz,org)/20., 2. ), 1. ))*float(p.y>.05));
}

//Main
void main( void )
{
	skyInit();
	
	//camera ray
	float ctime = (time+140.)*.07;
	vec3 org = vec3( cos(ctime)*(8.-CC[0]*2.), 4., sin(ctime)*(8.-CC[0]*2.) );
	vec3 dir = normalize( vec3(v.x, v.y, 1.5-length(v)*(1.+CC[0])) );
	dir = lookat( -org + vec3(0., 2., 0.), vec3(0., 1., 0.) ) * dir;
	
	//classic raymarching by distance field
	vec4 p = raymarche(org, dir, vec2(2., 20.) );
	vec3 n = normal(p.xyz);
	vec4 col = shade(p, n, org, dir);
	
	//post process
    col = pow( col*1.75, vec4(vec3(2.5),1.) );
	
	gl_FragColor = col;
}




void skyInit()
{
	skyProcedural(vec3(0.),vec3(0.));
	sunColor = skyProcedural(vec3(0.),sunDirection);
}
	
vec3 skyProcedural( in vec3 origin, in vec3 direction )
{
	const float a_exposure = 0.05;
	const float T=2.2;
	const float J=240.;//Mon anniv 
	const float latitude=43.17; //A marseille !
	
	
	vec3 zenith_direction = vec3(0.0, 1.0, 0.0);
	direction.y=max(direction.y,.0001);
	vec4 color = vec4(1.0);
	float d = 0.4093*sin(2.0*PI*(J-81.0)/368.0);
	float l = latitude*PI/180.0;
	float thetas = PI/2.0 - asin(sin(l)*sin(d)-cos(l)*cos(d)*cos(PI*daytime/12.0));
	thetas = clamp(thetas, 0.0, 1.62);
	float phis = atan(-cos(d)*sin(PI*daytime/12.0),(cos(l)*sin(d)-sin(l)*cos(d)*cos(PI*daytime/12.0)));

	sunDirection = vec3(sin(thetas)*cos(phis), cos(thetas), sin(thetas)*sin(phis));
	
	vec3 Tvec3 = vec3(T, 1.0, 0.0);
	
	// Should be transposed..
	vec3 A = mat3(-0.0193, -0.0167,  0.1787,
        	      -0.2592, -0.2608, -1.4630,
        	       0.0,     0.0,     0.0) * Tvec3;
	vec3 B = mat3(-0.0665, -0.0950, -0.3554,
                   0.0008,  0.0092,  0.4275,
                   0.0,     0.0,     0.0) * Tvec3;
    vec3 C = mat3(-0.0004, -0.0079, -0.2270,
                   0.2125,  0.2102,  5.3251,
                   0.0,     0.0,     0.0) * Tvec3;
    vec3 D = mat3(-0.0641, -0.0441,  0.1206,
                  -0.8989, -1.6537, -2.5771,
                   0.0,     0.0,     0.0) * Tvec3;
    vec3 E = mat3(-0.0033, -0.0109, -0.0670,
                   0.0452,  0.0529,  0.3703,
                   0.0,     0.0,     0.0) * Tvec3;

	vec3 zenith_xyY;
	vec4 Tvec4 = vec4(T*T, T, 1.0, 0.0);
	vec4 thetasvec = vec4(pow(thetas, 3.), pow(thetas, 2.), thetas, 1.);
	zenith_xyY.z = (4.0453*T - 4.9710)*tan((4.0/9.0 - T/120.0)*(PI-2.0*thetas)) - 0.2155*T + 2.4192;
	zenith_xyY.x = dot(thetasvec, mat4( 0.00166, -0.00375,  0.00209, 0.0,
	                                   -0.02903,  0.06377, -0.03202, 0.00394,
	                                    0.11693, -0.21196,  0.06052, 0.25886,
	                                    0.0,      0.0,      0.0,     0.0) * Tvec4);
	zenith_xyY.y = dot(thetasvec, mat4( 0.00275, -0.00610,  0.00317, 0.0,
	                                   -0.04214,  0.08970, -0.04153, 0.00516,
	                                    0.15346, -0.26756,  0.06670, 0.26688,
	                                    0.0,      0.0,      0.0,     0.0) * Tvec4 );

	float costheta = dot( zenith_direction, direction );
	float cosgamma = dot( sunDirection, direction );
	float cos2gamma = cosgamma*cosgamma;
	float gamma = acos(cosgamma);
	
	vec3 num = ( 1.0 + A * exp( B/costheta ) ) * ( 1.0 + C * exp( D*gamma ) + E * cos2gamma );
	vec3 den = ( 1.0 + A * exp( B ) ) * ( 1.0 + C * exp( D * thetas ) + E * pow(cos(thetas),2.) );
	vec3 xyY = num/den * zenith_xyY;
	
	xyY.z = 1.0 - exp( -a_exposure * xyY.z);
	
	vec3 XYZ;
	XYZ.x = (xyY.x	/ xyY.y) * xyY.z;
	XYZ.y = xyY.z;
	XYZ.z = ((1.0 - xyY.x - xyY.y) / xyY.y ) * xyY.z;
	
	// mat3 constructor is column major, so the Rec 709 matrix must be transposed
	vec3 rgb = mat3( 3.240479, -0.969256,  0.055648,
	                -1.537150,  1.875992, -0.204043,
	                -0.498535,  0.041556,  1.057311) * XYZ;
	vec3 sun = vec3(1.0,0.5,0.1)*pow(max(dot(direction,sunDirection),0.0),512.0);

	return clamp( rgb, vec3(0.0), vec3(1.0))+sun;
}

