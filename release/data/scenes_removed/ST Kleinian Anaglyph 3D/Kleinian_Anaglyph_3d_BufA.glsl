
//-----------------------------------------------------
// Kleinian_Anaglyph_3d_BufA.glsl
// calculate left eye view (red)
//-----------------------------------------------------

void mainImage(out vec4 fragColor, vec2 fragCoord ) 
{
  commonRender(fragColor, fragCoord, true, 0.1 * iTime, iResolution.xy);
}