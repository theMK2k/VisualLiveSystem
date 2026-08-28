varying vec2 v;
uniform sampler2D lastBuffer,mask;
uniform float CC[4];
vec2 screen = vec2(320.,180.);

void main()
{
    vec4 color;
    vec2 uv = v*.5+.5;
    vec2 offset = -v*vec2(16./9.,.5)/screen*1.5;



    vec4 lightray = vec4(0.);
    for(int i=0; i<64; i++)
    {
        lightray += pow(texture2D(lastBuffer, uv+offset*float(i)),vec4(2.))  / float(1.+float(i)*2.)  ;
    }
    gl_FragColor.rgb = lightray.rgb*(1.+CC[0]*5.);
    gl_FragColor.a = 1.;
}
