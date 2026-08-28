varying vec2 v;
uniform sampler2D lastBuffer;
vec2 screen = vec2(320.);

void main()
{
    vec4 color;
    vec2 uv = v*.5+.5;
    vec2 offset = (vec2(0.,-.5)-v)/screen*1.5;



    vec4 lightray = vec4(0.);
    for(int i=0; i<64; i++)
    {
        if(uv.x+offset.x*float(i)<.99)
        {
            float mask = texture2D(lastBuffer, uv+offset*float(i)).a;
            lightray += texture2D(lastBuffer, uv+offset*float(i))*mask/float(1.+float(i));
        }
    }

    color = texture2D(lastBuffer, uv );
    gl_FragColor.rgb = lightray.rgb*.1;
    gl_FragColor.a = 1.;
}
