#import "shaders/convolution_filter.wgsl"::create_filter
#import "shaders/convolution_filter.wgsl"::apply_filter_on_depth_buffer
#import "shaders/convolution_filter.wgsl"::apply_filter

fn detect_edge(id: vec2<f32>, deep_buffer: texture_depth_2d, normal_map: texture_2d<f32>) -> f32 {
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

    let depth_x = vec3f(apply_filter_on_depth_buffer(id, deep_buffer, sobel_x));
    let depth_y = vec3f(apply_filter_on_depth_buffer(id, deep_buffer, sobel_y));
    let depth = sqrt(dot(depth_x, depth_x) + dot(depth_y, depth_y));

    let normal_x = apply_filter(id, normal_map, sobel_x);
    let normal_y = apply_filter(id, normal_map, sobel_y);
    let normal = sqrt(dot(normal_x, normal_x) + dot(normal_y, normal_y));

    return max(depth, normal);
}