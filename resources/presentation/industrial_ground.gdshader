// Static world-space concrete: presentation only, with no textures, time or displacement.
shader_type spatial;
render_mode diffuse_burley;
uniform vec4 concrete_color : source_color = vec4(0.56,0.56,0.535,1.0);
uniform vec4 paths[6];
uniform vec4 chases[9];
varying vec3 world_position;
varying vec3 world_normal;
float hash21(vec2 p) {
	p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);return fract(p.x*p.y);
}
float noise21(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
vec2 segment(vec2 p,vec4 ab) {
	vec2 span=ab.zw-ab.xy;float t=clamp(dot(p-ab.xy,span)/max(dot(span,span),0.001),0.0,1.0);
	return vec2(length(p-(ab.xy+t*span)),t*length(span));
}
float stain(vec2 p,vec2 at,vec2 extent,float grain) {
	float d=length((p-at)/extent);return (1.0-smoothstep(0.45,1.1,d+(grain-0.5)*0.3));
}
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	vec2 p=world_position.xz;
	float coarse=noise21(p*0.16);
	float medium=noise21(p*1.3);
	float fine=noise21(p*14.0);
	// Eight-metre slab seams and low-contrast aggregate.
	vec2 cell=floor((p+vec2(36,32))/8.0);
	vec2 tile=mod(p+vec2(36,32),8.0);
	vec2 edge=min(tile,8.0-tile);
	float joint_distance=min(edge.x,edge.y);
	float aa=max(length(fwidth(p))*.5,0.004);
	float joint=1.0-smoothstep(0.006,0.016+aa,joint_distance);
	float shoulder=1.0-smoothstep(0.025,0.12+aa,joint_distance);
	float slab=hash21(cell);
	vec3 base=concrete_color.rgb*(0.96+0.06*slab+0.17*(coarse-.5)+0.075*(medium-.5)+0.035*(fine-.5));
	base*=1.0-0.055*shoulder;
	base=mix(base,base*0.48,joint*0.46);
	// Static paired tyre wear along authored circulation lines.
	float track=0.0;float scrub=0.0;
	for(int i=0;i<6;i++) {
	 vec2 route=segment(p,paths[i]);
	 float paired=abs(route.x-0.68);
	 float tire=(1.0-smoothstep(0.09,0.21+aa,paired))*(0.35+0.65*noise21(vec2(route.y*0.45,float(i)+3.0)));
	 track=max(track,tire);
	 scrub=max(scrub,(1.0-smoothstep(0.8,1.6,route.x))*0.05);
	}
	base=mix(base,base*0.40,track*0.60);
	base+=vec3(0.03)*scrub;
	// Local stains stay subdued around equipment and secured loads.
	float oil=stain(p,vec2(-18,4.6),vec2(2.3,.9),medium)*.48;
	oil=max(oil,stain(p,vec2(-16,16.9),vec2(1.7,.7),medium)*.27);
	oil=max(oil,stain(p,vec2(22,11.0),vec2(1.8,1.0),medium)*.27);
	oil=max(oil,stain(p,vec2(-1,8.9),vec2(2.7,.65),medium)*.23);
	base=mix(base,vec3(.055,.051,.044),oil);
	// Flush covered services are shading only, with half-metre plate joints.
	float channel=0.0;float cover=0.0;
	for(int i=0;i<9;i++) {
	 vec2 run=segment(p,chases[i]);
	 float outer=1.0-smoothstep(.11,.13+aa,run.x);
	 float panel=1.0-smoothstep(.085,.10+aa,run.x);
	 float gap=1.0-smoothstep(.005,.012+aa,min(mod(run.y,.5),.5-mod(run.y,.5)));
	 channel=max(channel,outer);
	 cover=max(cover,panel*(1.0-.6*gap));
	}
	base=mix(base,vec3(.10,.11,.11),channel*.8);
	base=mix(base,vec3(.25,.27,.27)*(0.95+medium*.1),cover*.8);
	float top=smoothstep(.5,.9,world_normal.y);
	ALBEDO=mix(concrete_color.rgb,base,top);
	ROUGHNESS=mix(.93,.71,oil)* (1.0-cover*.08);
	METALLIC=cover*.22;
}
