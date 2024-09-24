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
#import "shaders/convolution_filter.wgsl"::create_filter
#import "shaders/convolution_filter.wgsl"::create_filter_from_scalar
#import "shaders/convolution_filter.wgsl"::apply_filter_on_depth_buffer
#import "shaders/convolution_filter.wgsl"::apply_filter



@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
@group(0) @binding(3) var depth_prepass_texture: texture_depth_2d;

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let resolution = vec2<f32>(textureDimensions(screen_texture));

    let identity = create_filter(
        0.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 0.0,
    );

    let sharpen = create_filter(
        0.0, -1.0, 0.0,
        -1.0, 5.0, -1.0,
        0.0, -1.0, 0.0,
    );

    let mean_blur = create_filter_from_scalar(1.0/9.0);

    let leplecian = create_filter(
        0.0, 1.0, 0.0,
        1.0, -4.0, 1.0,
        0.0, 1.0, 0.0,
    );

    let gauss = create_filter(
        1.0/16.0, 2.0/16.0, 1.0/16.0,
        2.0/16.0, 4.0/16.0, 2.0/16.0,
        1.0/16.0, 2.0/16.0, 1.0/16.0,
    );

    let sobel_x = create_filter(
         1.0,  2.0, 1.0,
         0.0,  0.0, 0.0,
        -1.0, -2.0, -1.0,
    );

    let sobel_y = create_filter(
        1.0, 0.0, -1.0,
        2.0, 0.0, -2.0,
        1.0, 0.0, -1.0,
    );
    let depth = textureLoad(depth_prepass_texture, vec2<i32>(in.position.xy), 0);

    let x = apply_filter(in.uv, screen_texture, texture_sampler, resolution, sobel_x).rgb;
    let y = apply_filter(in.uv, screen_texture, texture_sampler, resolution, sobel_y).rgb;

    let depth_x = apply_filter_on_depth_buffer(in.position.xy, depth_prepass_texture, sobel_x);
    let depth_y = apply_filter_on_depth_buffer(in.position.xy, depth_prepass_texture, sobel_y);

    return vec4<f32>(
        vec3(depth_x + depth_y).rgb,
        1.0
    );

}