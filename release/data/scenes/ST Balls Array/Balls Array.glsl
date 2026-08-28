varying vec2 v;
uniform float time, bassTime, bass, CC[4];
uniform sampler2D rnd, tex, tule;

/*
	ST Balls Array v1.0
	ported from ShaderToy by MK2k https://mk2k.net
	ShaderToy URL:   https://www.shadertoy.com/view/???? (2018-11-01)
	Original Author: https://www.shadertoy.com/user/????

	-- Port Notes --
	Camera Movement is influenced by bassTime
*/

float field (vec3 pos, vec3 rawPos) {
    //float b = texture( iChannel1, vec2(20./256.,0.25) ).x;
    return length(pos) - (0.8);
}

vec3 normal (vec3 p) {
    vec2 eps = vec2(0.001, 0.0);
    return normalize(vec3(
    	field(p + eps.xyy, p) - field(p - eps.xyy, p),
        field(p + eps.yxy, p) - field(p - eps.yxy, p),
        field(p + eps.yyx, p) - field(p - eps.yyx, p)
    ));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// vec2 uv = fragCoord.xy / iResolution.xy;
  // uv = uv*2.0-1.0;
  // uv.x *= iResolution.x/iResolution.y;

	vec2 uv = (v);	// MK2k

    fragColor = vec4(1.0);
    
    vec3 ro = vec3(uv, -2);
    vec3 rd = normalize(vec3(uv*0.25, 1.0));
    
    float h = 0.0;
    float last = 9999.0;
    for (int i = 0; i < 100; ++i) {
     	vec3 pos = ro+h*rd;
        float fog = exp(-length(pos) * 0.05);
        float fog2 = exp(-length(pos) * 0.025);

        float fTime = (time*0.5 + bassTime)*0.5;
        pos.xz *= mat2(sin(fTime),cos(fTime),cos(fTime),-sin(fTime));
        pos.xy *= -mat2(sin(fTime),cos(fTime),cos(fTime),-sin(fTime));
        
       	pos.x += fTime * 4.0 * 8.0;

		//pos.z += ifTime*4.0;
        vec3 rawPos = pos;
    	pos = mod(pos+3.0, 6.0)-3.0;
        
        float hit = field(pos, rawPos);
        h += max(0.0025, hit);
        if (h > 200.0) break;
                
        if (hit < 1.0) {
            if (hit < 0.1)
                last = hit;  
            else {
                if (last < 0.1) {
                    fragColor = vec4(0.0);
                    fragColor = mix(vec4(1.0), fragColor, fog2);
                    break;
                } else last = 9999.0;
            }
        }
        
        if (hit < 0.1) {
            vec3 n = normal(pos);
            float diff = clamp(dot(n, normalize(vec3(1,1,-1))), 0.0, 1.0);
            float sky = clamp(dot(n, normalize(vec3(-1,1,0))), 0.0, 1.0);
            //vec4 cubemap = texture(iChannel0, n);
            diff = mix(0.025, 1.0, diff);
            sky = mix(0.025, 1.0, sky);
        	fragColor = vec4(vec3(1.0,0.9,0.5)*diff + vec3(0.3, 0.5, 0.75)*0.5*sky /* + cubemap.rgb * 0.5 * diff */, 1.0);
        	
            fragColor = mix(vec4(1.0), fragColor, fog);
            
        }
    }
    
    //vec2 uv2 = fragCoord.xy / iResolution.xy;
    //uv2 = uv2 * 2.0 - 1.0;
	vec2 uv2 = v;
    fragColor *= smoothstep(1.65, 1.65 - 0.75, length(uv2));
    
    fragColor = pow(fragColor, vec4(0.45));
}

// This is hidden from Shadertoy
void main() {
	mainImage(gl_FragColor,gl_FragCoord.xy);
}
