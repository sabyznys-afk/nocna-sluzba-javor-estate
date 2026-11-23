shader_type canvas_item;

// Authentic 1997 PlayStation 1 Post-Render Pass (placed BELOW HUD UI layer so UI text stays 100% crisp!):
// - True nearest-neighbor low-resolution pixelation (426x240, 512x288, or 640x360)
// - Authentic PS1 4x4 Bayer ordered dithering + 15-bit (RGB555) quantization
// - Live calibrated Brightness, Gamma & Contrast controls without crushing dark-scene readability!

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 internal_resolution = vec2(512.0, 288.0);
uniform float dither_strength : hint_range(0.0, 1.0) = 0.65;
uniform float color_levels : hint_range(16.0, 255.0) = 32.0; // 32 = authentic PS1 15-bit RGB555
uniform float distortion : hint_range(0.0, 1.0) = 0.04;
uniform float monochrome_mix : hint_range(0.0, 1.0) = 0.0;
uniform float crt_intensity : hint_range(0.0, 1.0) = 0.28;
uniform float curvature : hint_range(0.0, 0.25) = 0.0;
uniform float brightness_val : hint_range(0.5, 1.8) = 1.08;
uniform float gamma_val : hint_range(0.5, 1.8) = 1.0;
uniform float contrast_val : hint_range(0.6, 1.6) = 1.0;

float bayer4x4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = y * 4 + x;
	if (idx == 0) return 0.0 / 16.0;
	if (idx == 1) return 8.0 / 16.0;
	if (idx == 2) return 2.0 / 16.0;
	if (idx == 3) return 10.0 / 16.0;
	if (idx == 4) return 12.0 / 16.0;
	if (idx == 5) return 4.0 / 16.0;
	if (idx == 6) return 14.0 / 16.0;
	if (idx == 7) return 6.0 / 16.0;
	if (idx == 8) return 3.0 / 16.0;
	if (idx == 9) return 11.0 / 16.0;
	if (idx == 10) return 1.0 / 16.0;
	if (idx == 11) return 9.0 / 16.0;
	if (idx == 12) return 15.0 / 16.0;
	if (idx == 13) return 7.0 / 16.0;
	if (idx == 14) return 13.0 / 16.0;
	return 5.0 / 16.0;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	// 1. Exact nearest-neighbor pixel grid downsampling of the 3D scene
	vec2 res = max(internal_resolution, vec2(160.0, 90.0));
	vec2 pix_coord = floor(SCREEN_UV * res);
	vec2 snapped_uv = (pix_coord + vec2(0.5)) / res;

	// Subtle horizontal VHS/CRT sync jitter only on high distortion / horror events
	float stress = max(0.0, distortion - 0.18);
	if (stress > 0.01) {
		float line_shift = (hash12(vec2(pix_coord.y, floor(TIME * 14.0))) - 0.5) * stress * 0.014;
		snapped_uv.x = clamp(snapped_uv.x + line_shift, 0.0, 1.0);
	}

	vec3 col = texture(screen_texture, snapped_uv).rgb;

	// 2. Consistent 1996 Central European PS1 Horror Palette (preserves readable shadows!)
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(vec3(luma), col, 0.82);
	vec3 shadow_tint = desat * vec3(0.88, 0.96, 1.04);
	vec3 lit_tint = desat * vec3(1.05, 0.97, 0.84);
	vec3 graded = mix(shadow_tint, lit_tint, smoothstep(0.06, 0.45, luma));

	// Live user Brightness, Contrast & Gamma calibration (never crushes near-black detail to pure zero!)
	graded = max(graded, vec3(0.0));
	graded = pow(graded, vec3(1.0 / clamp(gamma_val, 0.55, 1.75)));
	graded *= clamp(brightness_val, 0.60, 1.75);
	graded = clamp((graded - 0.5) * clamp(contrast_val, 0.65, 1.55) + 0.5, 0.0, 1.0);

	// 3. Bunker K-4 subtle cold phosphor shift when underground
	vec3 phosphor = vec3(luma * 0.72, luma * 0.95, luma * 0.76);
	graded = mix(graded, phosphor, monochrome_mix * 0.78);

	// 4. Authentic PS1 Ordered Bayer 4x4 Dithering + Color Depth Quantization (RGB555)
	float bayer = bayer4x4(pix_coord) - 0.5;
	float levels = max(16.0, color_levels);
	if (levels < 240.0 && dither_strength > 0.01) {
		vec3 dithered = graded + (bayer * dither_strength) / levels;
		graded = floor(clamp(dithered, 0.0, 1.0) * levels + 0.5) / levels;
	}

	// 5. Subtle CRT scanline cadence + gentle edge vignette (keeps peripheral paths visible!)
	float scan = 1.0 - (mod(pix_coord.y, 2.0) * 0.045 * clamp(crt_intensity, 0.0, 1.0));
	graded *= scan;

	vec2 centered = SCREEN_UV - 0.5;
	float vig = clamp(1.0 - dot(centered, centered) * (0.42 + stress * 0.35), 0.62, 1.0);
	graded *= vig;

	COLOR = vec4(clamp(graded, 0.0, 1.0), 1.0);
}
