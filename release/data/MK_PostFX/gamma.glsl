varying vec2 v;
uniform sampler2D lastBuffer,mask;
uniform float bass, CC[4];

/*
	postprocess.glsl

	Modified postprocess for use with single scenes using their own offset and bass fx (CC[0] and CC[1])
*/

void main()
{
	vec2 tmp = gl_TexCoord[0].xy*2.-1.;
	vec2 uv = tmp;
	uv = uv * 0.5 + 0.5;

	vec3 col = texture2D(lastBuffer,uv).rgb;

	// col = pow( col, vec3(8.-(0.0 + CC[0]*8. + CC[1]*bass*8.)) );	// gamma

	// vec3 gray = vec3(dot(col,vec3(0.33)));

	col *= (0.0 + CC[0]*2.5 + CC[1]*bass*2.5);	// brightness based on indiviual setting in CC[0] (offset) and bass amplified by CC[1] (bass fx)

	//col = mix(gray, col, 1.+contrast);
	//col = mix( col, gray, desaturate );
	
	gl_FragColor.rgb = col;
	gl_FragColor.a = 1.0;
}
