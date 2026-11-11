shader_type canvas_item;
render_mode unshaded;
uniform vec2 outline[20];
void fragment(){
	vec2 point=UV*vec2(768.0,648.0);
	float edge_distance=10000.0;
	for(int i=0;i<20;i++){
		vec2 a=outline[i];vec2 b=outline[(i+1)%20];vec2 ab=b-a;
		float fraction=clamp(dot(point-a,ab)/max(dot(ab,ab),.00001),0.0,1.0);
		edge_distance=min(edge_distance,length(point-a-ab*fraction));
	}
	float feather=mix(6.0,1.25,smoothstep(475.0,520.0,point.y));
	vec4 skin=texture(TEXTURE,UV);
	skin.a*=smoothstep(0.0,feather,edge_distance);
	COLOR=skin;
}
