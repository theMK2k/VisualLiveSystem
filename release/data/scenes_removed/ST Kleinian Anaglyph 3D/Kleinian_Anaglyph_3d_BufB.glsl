
//-----------------------------------------------------
// Kleinian_Anaglyph_3d_BufB.glsl
// calculate right eye view (cyan)
//-----------------------------------------------------

void mainImage(out vec4 fragColor, vec2 fragCoord ) 
{
  commonRender(fragColor, fragCoord, false, 0.1 * iTime, iResolution.xy);
}