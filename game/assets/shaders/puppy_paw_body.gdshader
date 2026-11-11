shader_type canvas_item;
render_mode unshaded;
uniform sampler2D repaired_skin : source_color, filter_linear_mipmap;
uniform vec2 outline[20];

void fragment() {
	vec2 point=UV*vec2(768.0,648.0);
	bool inside=false;
	float edge_distance=10000.0;
	for(int i=0;i<20;i++){
		vec2 a=outline[i];vec2 b=outline[(i+1)%20];
		vec2 ab=b-a;
		float fraction=clamp(dot(point-a,ab)/max(dot(ab,ab),0.00001),0.0,1.0);
		edge_distance=min(edge_distance,length(point-a-ab*fraction));
		if((a.y>point.y)!=(b.y>point.y)){
			float cross_x=a.x+(point.y-a.y)*(b.x-a.x)/(b.y-a.y);
			if(point.x<cross_x)inside=!inside;
		}
	}
	float signed_distance=inside?edge_distance:-edge_distance;
	float repair=smoothstep(-2.0,0.0,signed_distance);
	vec4 original=texture(TEXTURE,UV);
	vec4 hidden=texture(repaired_skin,UV);
	COLOR=mix(original,hidden,repair);
}
