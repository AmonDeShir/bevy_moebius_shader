// This shader computes the chromatic aberration effect

// Since post processing is a fullscreen effect, we use the fullscreen vertex shader provided by bevy.
// This will import a vertex shader that renders a single fullscreen triangle.
//
// A fullscreen triangle is a single triangle that covers the entire screen.
// The box in the top left in that diagram is the screen. The 4 x are the corner of the screen
//
// Y axis
//  1 |  x-----x......
//  0 |  |  s  |  . ´
// -1 |  x_____x´
// -2 |  :  .´
// -3 |  :´
//    +---------------  X axis
//      -1  0  1  2  3
//
// As you can see, the triangle ends up bigger than the screen.
//
// You don't need to worry about this too much since bevy will compute the correct UVs for you.
#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import "shaders/edge_detection.wgsl"::detect_edge
#import "shaders/simplex_noise.wgsl"::simplex_noise_2d

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
@group(0) @binding(3) var depth_prepass_texture: texture_depth_2d;
@group(0) @binding(4) var normal_prepass_texture: texture_2d<f32>;

fn grayscale(gamma: vec3<f32>) -> f32 {
    return (gamma.r + gamma.g + gamma.b) / 3.0;
}

fn draw_shadow(color: vec3<f32>) -> vec4<f32> {
    let brightness = grayscale(color);

    if brightness < 0.05 {
        return vec4(0.01, 0.01, 0.01, 1.0);
    }

    if brightness < 0.07 {
        return vec4(0.03, 0.03, 0.03, 1.0);
    }

    if brightness < 0.1 {
        return vec4(0.05, 0.05, 0.05, 1.0);
    }

    if brightness < 0.5 {
        return vec4(0.5, 0.5, 0.5, 1.0);
    }

    return vec4(1, 1, 1, 1.0);
}

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let noise = simplex_noise_2d(in.uv * 50) * 0.0;
    let edge = detect_edge(in.position.xy + noise, depth_prepass_texture, normal_prepass_texture);

    if edge > 0.8 {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    let color = textureSample(screen_texture, texture_sampler, in.uv).rgb;

    return draw_shadow(color);
}