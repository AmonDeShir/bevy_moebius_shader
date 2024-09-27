use bevy::pbr::{ExtendedMaterial, MaterialExtension};
use bevy::prelude::*;
use bevy::render::primitives::Aabb;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};
use bevy::render::texture::{ImageAddressMode, ImageLoaderSettings, ImageSampler, ImageSamplerDescriptor};

pub struct MoebiusMaterialPlugin;

impl Plugin for MoebiusMaterialPlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins(MaterialPlugin::<ExtendedMaterial<StandardMaterial, MoebiusMaterial>>::default());
        app.register_type::<ForceMoebiusMaterial>();
        app.add_systems(PreStartup, load_moebius_material_assets);
        app.observe(on_force_moebius_material_spawn);
    }
}

#[derive(Resource, Reflect)]
#[reflect(Resource)]
struct MoebiusMaterialAssets {
    pub shadow_texture: Handle<Image>
}

fn load_moebius_material_assets(mut asset_server: ResMut<AssetServer>, mut commands: Commands) {
    commands.insert_resource(MoebiusMaterialAssets {
        shadow_texture: asset_server.load_with_settings(
            "shadows.png",
            |s: &mut _| {
                *s = ImageLoaderSettings {
                    sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                        address_mode_u: ImageAddressMode::Repeat,
                        address_mode_v: ImageAddressMode::Repeat,
                        address_mode_w: ImageAddressMode::Repeat,
                        ..default()
                    }),
                    ..default()
                }
            },
        )
    });
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
pub struct MoebiusMaterial {
    #[texture(100)]
    #[sampler(101)]
    shadow_texture: Handle<Image>,
    #[uniform(102)]
    model_size: Vec3
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

fn on_force_moebius_material_spawn(
    trigger: Trigger<OnInsert, ForceMoebiusMaterial>,
    mut query: Query<(&Handle<StandardMaterial>, &Aabb), With<ForceMoebiusMaterial>>,
    mut mobius_materials: ResMut<Assets<ExtendedMaterial<StandardMaterial, MoebiusMaterial>>>,
    assets: Res<MoebiusMaterialAssets>,
    pbr_materials: Res<Assets<StandardMaterial>>,
    mut commands: Commands
) {
    let Ok((material_handle, aabb)) = query.get(trigger.entity()) else {
        return;
    };

    let Some(material) = pbr_materials.get(material_handle) else {
        return;
    };

    let mut entity = commands.entity(trigger.entity());
    let custom = mobius_materials.add(ExtendedMaterial {
        base: material.clone(),
        extension: MoebiusMaterial {
            shadow_texture: assets.shadow_texture.clone(),
            model_size: aabb.half_extents.into(),
        }
    });

    entity.insert(custom).remove::<Handle::<StandardMaterial>>();
}