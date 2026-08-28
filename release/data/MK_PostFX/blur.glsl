varying vec2 v;
uniform sampler2D lastBuffer,mask;
uniform float bass, CC[4];

// https://www.shadertoy.com/view/XdfGDH

float normpdf(in float x, in float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

void main()
{
	vec2 tmp = gl_TexCoord[0].xy*2.-1.;
	vec2 uv = tmp;
	uv = uv * 0.5 + 0.5;

	vec3 c = texture2D(lastBuffer, uv).rgb;
	// if (fragCoord.x < iMouse.x)
	// {
	// gl_FragColor = vec4(c, 1.0);	
	// } else {

		//declare stuff
		int mSize = 1 + 2 * int(clamp(bass * CC[1], 0.0, 1.0) * 5.0);
		int kSize = (mSize-1)/2;
		float kernel[11];
		vec3 final_colour = vec3(0.0);

		//create the 1-D kernel
		float sigma = 7.0;
		float Z = 0.0;
		for (int j = 0; j <= kSize; ++j)
		{
			kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
		}

		//get the normalization factor (as the gaussian has been clamped)
		for (int j = 0; j < mSize; ++j)
		{
			Z += kernel[j];
		}

		//read out the texels
		for (int i=-kSize; i <= kSize; ++i)
		{
			for (int j=-kSize; j <= kSize; ++j)
			{
				final_colour += kernel[kSize+j]*kernel[kSize+i]*texture2D(lastBuffer, (gl_FragCoord.xy+vec2(float(i),float(j))) / vec2(640, 480).xy).rgb;
	
			}
		}

		gl_FragColor = vec4(final_colour/(Z*Z), 1.0);
	// }
}
