#import bevy_pbr::{
    pbr_fragment::pbr_input_from_standard_material,
    pbr_functions::alpha_discard,
}

#ifdef PREPASS_PIPELINE
#import bevy_pbr::{
    prepass_io::{VertexOutput, FragmentOutput},
    pbr_deferred_functions::deferred_output,
}
#else
#import bevy_pbr::{
    forward_io::{VertexOutput, FragmentOutput},
    pbr_functions::{apply_pbr_lighting, main_pass_post_lighting_processing},
}
#endif

struct MyExtendedMaterial {
    quantize_steps: u32,
}

@group(2) @binding(100)
var<uniform> my_extended_material: MyExtendedMaterial;

fn grayscale(gamma: vec4<f32>) -> f32 {
    return (gamma.r + gamma.g + gamma.b) / 3.0;
}

@fragment
fn fragment(
    in: VertexOutput,
    @builtin(front_facing) is_front: bool,
) -> FragmentOutput {
    // generate a PbrInput struct from the StandardMaterial bindings
    var pbr_input = pbr_input_from_standard_material(in, is_front);

    // we can optionally modify the input before lighting and alpha_discard is applied
    //pbr_input.material.base_color.b = pbr_input.material.base_color.r;

    // alpha discard
    pbr_input.material.base_color = alpha_discard(pbr_input.material, pbr_input.material.base_color);

#ifdef PREPASS_PIPELINE
    // in deferred mode we can't modify anything after that, as lighting is run in a separate fullscreen shader.
    let out = deferred_output(in, pbr_input);
#else
    var out: FragmentOutput;
    // apply lighting

    let shadow = 1.0 - grayscale(pbr_input.material.base_color - apply_pbr_lighting(pbr_input));

    out.color = pbr_input.material.base_color;

    // Strong Shadow
    if shadow < 0.5 {
        out.color -= vec4(1.00, 1.00, 1.00, 0.0);
    }

    // Middle Shadow
    else if shadow < 0.8 {
        out.color -= vec4(0.50, 0.5, 0.50, 0.0);
    }

    // Light Shadow
    else if shadow < 1.0 {
        out.color -= vec4(0.01, 0.01, 0.01, 0.0);
    }

    // apply in-shader post processing (fog, alpha-premultiply, and also tonemapping, debanding if the camera is non-hdr)
    // note this does not include fullscreen postprocessing effects like bloom.
    //out.color = main_pass_post_lighting_processing(pbr_input, out.color);


#endif

    return out;
}