

#define U4 uint
#define U4x2 uvec2
#define U4x3 uvec3
#define U4x4 uvec4
//
#define F4 float
#define F4x2 vec2
#define F4x3 vec3
#define F4x4 vec4




//=============================================================================================================================
//
// [HXD] HEX DUMP
//
//=============================================================================================================================
// Uses 4x8 bitmap characters.
//-----------------------------------------------------------------------------------------------------------------------------
// 000  0  000 000 0 0 000 000 000 000 000     0         0      00
// 0 0  0    0   0 0 0 0   0     0 0 0 0 0 000 000 000 000 000  0
// 0 0  0  000  00 0 0 000 000   0 000 000   0 0 0 0   0 0 0 0 000
// 0 0  0  0     0 000   0 0 0   0 0 0   0 0 0 0 0 0   0 0 0    0
// 000  0  000 000   0 000 000   0 000 000 000 000 000 000 000  0
//=============================================================================================================================
// Hex to bitmap.
U4 HxdTab(U4 h){U4 m=0u;
 if(h==0x0u)m=0x755570u;
 if(h==0x1u)m=0x222220u;
 if(h==0x2u)m=0x717470u;
 if(h==0x3u)m=0x746470u;
 if(h==0x4u)m=0x475550u;
 if(h==0x5u)m=0x747170u;
 if(h==0x6u)m=0x757170u;
 if(h==0x7u)m=0x444470u;
 if(h==0x8u)m=0x757570u;
 if(h==0x9u)m=0x747570u;
 if(h==0xau)m=0x754700u;
 if(h==0xbu)m=0x755710u;
 if(h==0xcu)m=0x711700u;
 if(h==0xdu)m=0x755740u;
 if(h==0xeu)m=0x715700u;
 if(h==0xfu)m=0x227260u;
 return m;}
//-----------------------------------------------------------------------------------------------------------------------------
// Given 'p' integer position, and bitmap 'm', returns pixel 1=on, 0=off.
U4 HxdChr(U4x2 p,U4 m){return 1u&(m>>(((p.y&7u)<<2u)+(p.x&3u)));}
//-----------------------------------------------------------------------------------------------------------------------------
// Given 'p' integer position, and number 'n', return pixel 1=on, 0=off. Zero is all off.
U4 HxdNum(U4x2 p,U4 n){if(n==0u)return 0u;return HxdChr(p,HxdTab(15u&(n>>((7u*4u)-(p.x&0x1cu)))));}
//-----------------------------------------------------------------------------------------------------------------------------
// Given 'p' integer position, pick color (1.0 or 0.5), checker pattern.
//  X - ..x..... - 32-bit value
//  Y - ....y... - even/odd line
F4 HxdCol(U4x2 p){return 0.5+F4(1u&((p.x>>5u)^(p.y>>3u)))*0.5;}








U4 Number(U4x2 p){return (p.x>>5u)+(p.y>>3u)*242993u;}
//
void mainImage(out vec4 fragColor,in vec2 fragCoord){
 U4x2 uv;
 uv.x=U4(fragCoord.x*0.5);
 uv.y=U4((iResolution.y-fragCoord.y)*0.5);   
 F4 i=HxdNum(uv,Number(uv))==1u?1.0:0.0;
 i*=HxdCol(uv);
 fragColor=F4x4(i,i,i,i);}