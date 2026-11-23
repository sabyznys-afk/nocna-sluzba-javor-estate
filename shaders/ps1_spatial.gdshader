shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Authentic 1997 PS1 3D Surface Shader (Prompt 08 Lighting & Triplanar UV Fix):
// - Per-pixel Lambertian lighting so flashlight cones & streetlamp pools illuminate every road, wall & floor cleanly!
// - Supports crisp world-space triplanar pixel UVs (matching StandardMaterial3D uv1_triplanar!) so large
//   asphalt roads, concrete sidewalks & panelak walls never stretch into giant blurry blocks!
// - Subtle screen-space GTE vertex snapping + nearest-neighbor crisp 64-256px pixel art textures

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_texture = true;
uniform bool use_triplanar = false;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);
uniform float jitter_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec2 snap_resolution = vec2(256.0, 144.0);
uniform vec3 emission_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float emission_energy = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_norm;

void vertex() {
	UV = UV * uv_scale.xy;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (jitter_strength > 0.01 && clip_pos.w > 0.05) {
		vec2 grid = mix(vec2(960.0, 540.0), snap_resolution, jitter_strength);
		vec2 snapped_ndc = floor((clip_pos.xy / clip_pos.w) * grid + 0.5) / grid;
		clip_pos.xy = snapped_ndc * clip_pos.w;
	}
	POSITION = clip_pos;
}

void fragment() {
	vec4 tex_col = vec4(1.0);
	if (use_texture) {
		if (use_triplanar) {
			vec3 an = abs(v_world_norm);
			vec2 tuv;
			if (an.y >= an.x && an.y >= an.z) {
				tuv = v_world_pos.xz * uv_scale.xz;
			} else if (an.x >= an.z) {
				tuv = v_world_pos.zy * uv_scale.zy;
			} else {
				tuv = v_world_pos.xy * uv_scale.xy;
			}
			tex_col = texture(albedo_tex, tuv);
		} else {
			tex_col = texture(albedo_tex, UV);
		}
	}
	ALBEDO = tex_col.rgb * albedo_color.rgb;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
	if (emission_energy > 0.001) {
		EMISSION = emission_color * emission_energy;
	}
}
