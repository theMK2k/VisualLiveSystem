
//-----------------------------------------------------
// https://www.shadertoy.com/view/lstyR4
// Kleinian_Anaglyph_3d_Image.glsl           2018-02-09
//
// Modified version of Anaglyph kleinian 3d fractal, see source code header.
// Slightly modified color merging & rearranged code to use common code.
// Press mouse button to view original coloring.
//
// Original by sebastien durand  https://www.shadertoy.com/view/ldSyRd
// Anaglyph by iapafoto          https://www.shadertoy.com/view/4lXyDM
//
// tags: 3d, anaglyph, stereo, fractal, kleinian
//-----------------------------------------------------

//#define VIGNETTING

void mainImage(out vec4 fragColor, vec2 fragCoord ) 
{
  vec2 uv = fragCoord / iResolution.xy;
  vec4 buff1 = texture(iChannel0, uv);   	
  vec4 buff2 = texture(iChannel1, uv); 

  vec4 col = buff1;  
    
/* original code   
  float b = (buff1.r + buff1.g + buff1.b)/3.;
  float r = (buff2.r + buff2.g + buff2.b)/3.;
  col = vec4(r*1.5,b,b,1.);
*/

  if (iMouse.z < 1.0)
  {                    // gray scale conversion
    float r = (buff1.r*0.3 + buff1.g*0.59 + buff1.b*0.11);    
    float c = (buff2.r*0.3 + buff2.g*0.59 + buff2.b*0.11);    
    col = vec4(r*1.0, c, c, 1.0);
  } 
    
#ifdef VIGNETTING
  col.rgb *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .3); 
#endif
    
  fragColor = 1.5*pow(col,vec4(.6,.6,.6,1.));
}