use bevy::pbr::{ExtendedMaterial, MaterialExtension};
use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

pub struct MoebiusMaterialPlugin;

impl Plugin for MoebiusMaterialPlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins(MaterialPlugin::<ExtendedMaterial<StandardMaterial, MoebiusMaterial>>::default());
        app.register_type::<ForceMoebiusMaterial>();
        app.observe(on_force_mobius_material_spawn);
    }
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
pub struct MoebiusMaterial {
    #[uniform(100)]
    quantize_steps: u32,
}

impl MaterialExtension for MoebiusMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/moebius_material.wgsl".into()
    }

    fn deferred_fragment_shader() -> ShaderRef {
        "shaders/moebius_material.wgsl".into()
    }
}

#[derive(Reflect, Component)]
#[reflect(Component)]
pub struct ForceMoebiusMaterial;

fn on_force_mobius_material_spawn(
    trigger: Trigger<OnInsert, ForceMoebiusMaterial>,
    mut query: Query<&Handle<StandardMaterial>, With<ForceMoebiusMaterial>>,
    mut mobius_materials: ResMut<Assets<ExtendedMaterial<StandardMaterial, MoebiusMaterial>>>,
    pbr_materials: Res<Assets<StandardMaterial>>,
    mut commands: Commands
) {
    let Ok(material_handle) = query.get(trigger.entity()) else {
        return;
    };

    let Some(material) = pbr_materials.get(material_handle) else {
        return;
    };

    let mut entity = commands.entity(trigger.entity());
    let custom = mobius_materials.add(ExtendedMaterial {
        base: material.clone(),
        extension: MoebiusMaterial {  quantize_steps: 3 }
    });

    entity.insert(custom).remove::<Handle::<StandardMaterial>>();
}