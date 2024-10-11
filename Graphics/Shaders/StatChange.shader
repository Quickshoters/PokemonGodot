shader_type canvas_item;

uniform sampler2D texture : hint_albedo; // Textura que vamos a usar
uniform float effect_speed = 20.0;       // Velocidad del efecto
uniform vec4 color_tint : hint_color = vec4(1.0, 1.0, 1.0, 1.0); // Tinte de color

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
    
    // Crear un efecto de desplazamiento en la textura según la velocidad
    float offset = sin(TIME * effect_speed) * 0.1;
    uv.y += offset;
    
    // Aplicar la textura con el efecto de desplazamiento
    vec4 tex_color = texture(texture, uv);
    
    // Aplicar el tinte de color
    COLOR = tex_color * color_tint;
}
