shader_type canvas_item;


uniform float visible_frac = 1.0;

void fragment() {
	if (UV.y >= visible_frac) {
		COLOR.a = 0.3;
	}
}
