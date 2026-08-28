varying vec2 v;
uniform sampler2D lastBuffer,mask;
vec2 screen = vec2(320.,180.);

void main()
{
    vec2 uv = v*.5+.5;
    vec2 o = vec2(1.)/screen;
    vec4 color = texture2D(lastBuffer, uv );
    color += texture2D(lastBuffer, uv+vec2( o.x, 0.) );
    color += texture2D(lastBuffer, uv+vec2(-o.x, 0.) );
    color += texture2D(lastBuffer, uv+vec2( 0., o.y) );
    color += texture2D(lastBuffer, uv+vec2( 0.,-o.y) );

    color += texture2D(lastBuffer, uv+vec2( o.x, o.y) );
    color += texture2D(lastBuffer, uv+vec2(-o.x, o.y) );
    color += texture2D(lastBuffer, uv+vec2( o.x,-o.y) );
    color += texture2D(lastBuffer, uv+vec2(-o.x,-o.y) );

    color /= 9.;
    if(v.x<0.)
        color = texture2D(lastBuffer, uv );

    gl_FragColor.rgb = color.rgb*.5;
    gl_FragColor.a = 1.;
}
