varying vec2 v;
uniform sampler2D lastBuffer,mask;
uniform float bass;
vec2 screen = vec2(320.,180.);

void main()
{
    vec4 color;
    vec2 uv = v*.5+.5;
    vec2 offset = vec2(normalize(-v))/screen;
    vec2 offset2 = v/150.;


    vec4 lightray = vec4(0.);
    for(int i=0; i<64; i++)
    {
        if(uv.x+offset.x*float(i)<.99)
        {
            float att = 1./float(1.+float(i)*2.)*min(length(v)*10.,1.);
            lightray.r += texture2D(lastBuffer, uv+offset*float(i)-offset2).r*texture2D(lastBuffer, uv+offset*float(i)-offset2).a * att ;
            lightray.g += texture2D(lastBuffer, uv+offset*float(i)).g*texture2D(lastBuffer, uv+offset*float(i)).a * att ;
            lightray.b += texture2D(lastBuffer, uv+offset*float(i)+offset2).b*texture2D(lastBuffer, uv+offset*float(i)+offset2).a * att ;
        }
    }


    gl_FragColor.rgb = (lightray.rgb+pow(texture2D(lastBuffer, uv*vec2(1.,0.)).grb+texture2D(lastBuffer, uv*vec2(1.,0.)+vec2(0.,1.)).bgr,vec3(4.))*3.)*(.5+bass);
    gl_FragColor.a = 1.;
}
