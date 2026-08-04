import {
  Scene, Camera, Node, SceneResourceFactory,
  PostProcessSettings, ToneMappingSettings, ToneMappingType, BloomSettings,
  VignetteSettings, ColorFringeSettings,
  RenderContext, RenderParameters,
  NodeType, Geometry, Material, MaterialType, MetallicRoughnessMaterial, Vec4
} from '@kit.ArkGraphics3D';
import { EffectParams } from '../model/EffectParams';
import { EffectPreset } from '../model/EffectPreset';
import { QuatMath, Quat } from '../util/QuatMath';

@ObservedV2
export class PostProcessViewModel {
  @Trace params: EffectParams = new EffectParams();
  @Trace sceneOption: SceneOptions | null = null;

  private scene: Scene | null = null;
  private cam: Camera | null = null;
  private rotateNode: Node | null = null;

  private yaw: number = 0;
  private pitch: number = 0;
  private baseYaw: number = 0;
  private basePitch: number = 0;

  private autoRotateTimer: number = -1;

  /** Our own material assigned over the whole model so we can recolor it.
   *  The loaded GLB ships with no materials, so we must supply one. */
  private bodyMaterial: MetallicRoughnessMaterial | null = null;

  /** Background swatches the UI can cycle through, applied behind the model. */
  static readonly BG_COLORS: string[] = ['#000000', '#101826', '#1E1412', '#0C1A12'];

  /** Model body swatches. Index 0 is a neutral silver (the reset/default look). */
  static readonly MODEL_COLORS: string[] = ['#CCCCCC', '#C9A227', '#C7CCD1', '#5B8DEF', '#C0554E'];

  initScene(): void {
    if (this.scene !== null) {
      return;
    }

    const rc: RenderContext | null = Scene.getDefaultRenderContext();
    if (rc !== null) {
      rc.getRenderResourceFactory();
      console.info('[codelab] RenderContext ready');
    }

    Scene.load($rawfile('model.glb'))
      .then(async (result: Scene) => {
        this.scene = result;
        const rf: SceneResourceFactory = this.scene.getResourceFactory();

        this.cam = await rf.createCamera({ name: 'mainCamera' });
        this.cam.enabled = true;
        this.cam.position.z = this.params.zoom;

        if (this.scene.root !== null) {
          this.boostEmissiveMarkers(this.scene.root, this.params.glow);
          try {
            const mat: Material = await rf.createMaterial(
              { name: 'bodyMat' }, MaterialType.METALLIC_ROUGHNESS);
            this.bodyMaterial = mat as MetallicRoughnessMaterial;
            // factor.y = roughness, factor.z = metallic, factor.w = reflectance.
            // Dielectric + semi-matte so the base color reads as a real color.
            const mrFactor: Vec4 = { x: 0.0, y: 0.55, z: 0.0, w: 0.5 };
            this.bodyMaterial.material.factor = mrFactor;
            this.attachBodyMaterial(this.scene.root);
            this.applyModelColor(this.params.modelColorIndex);
            this.reglow();
            console.info('[modelcolor] body material attached');
          } catch (e) {
            console.error(`[modelcolor] setup failed, skipping recolor: ${e}`);
          }
        }

        this.applyPostProcess();

        this.rotateNode = null;
        if (this.scene.root !== null) {
          console.info(`[node] ROOT = ${this.scene.root.name}`);
          const kids = this.scene.root.children;
          const kc: number = kids.count();
          console.info(`[node] root child count = ${kc}`);
          for (let i = 0; i < kc; i++) {
            const c: Node | null = kids.get(i);
            if (c !== null) {
              console.info(`[node] child[${i}] name="${c.name}" type=${c.nodeType}`);
              if (this.rotateNode === null && c.nodeType !== NodeType.CAMERA && c.nodeType !== NodeType.LIGHT) {
                this.rotateNode = c;
                console.info(`[node] rotate target -> "${c.name}"`);
              }
            }
          }
        }
        if (this.rotateNode === null) {
          this.rotateNode = this.scene.root;
        }

        this.sceneOption = {
          scene: this.scene,
          modelType: ModelType.SURFACE
        } as SceneOptions;

        this.applyRotation();
      })
      .catch((reason: string) => {
        console.error(`Failed to load GLB: ${reason}`);
      });
  }

  setBloomOn(on: boolean): void {
    this.params.bloomOn = on;
    this.applyPostProcess();
  }

  setToneType(type: ToneMappingType): void {
    this.params.toneType = type;
    this.applyPostProcess();
  }

  setExposure(value: number): void {
    this.params.exposure = value;
    this.applyPostProcess();
  }

  setScatter(value: number): void {
    this.params.scatter = value;
    this.applyPostProcess();
  }

  setVignetteOn(on: boolean): void {
    this.params.vignetteOn = on;
    this.applyPostProcess();
  }

  setVignette(value: number): void {
    this.params.vignette = value;
    this.applyPostProcess();
  }

  setFringeOn(on: boolean): void {
    this.params.fringeOn = on;
    this.applyPostProcess();
  }

  setFringe(value: number): void {
    this.params.fringe = value;
    this.applyPostProcess();
  }


  setGlow(value: number): void {
    this.params.glow = value;
    this.reglow();
  }

  /** Push the whole camera in/out by driving its Z position. */
  setZoom(value: number): void {
    this.params.zoom = QuatMath.clamp(value, 2.0, 12.0);
    if (this.cam !== null) {
      this.cam.position.z = this.params.zoom;
      this.renderOnce();
    }
  }

  /** Apply a named preset then re-run the post-process + glow passes. */
  applyPreset(preset: EffectPreset): void {
    preset.applyTo(this.params);
    this.applyPostProcess();
    this.reglow();
  }

  /** Restore every effect and camera value to its default. */
  resetDefaults(): void {
    this.stopAutoRotate();
    this.params.reset();
    this.yaw = 0;
    this.pitch = 0;
    if (this.cam !== null) {
      this.cam.position.z = this.params.zoom;
    }
    this.applyPostProcess();
    this.reglow();
    this.applyModelColor(this.params.modelColorIndex);
    this.applyRotation();
  }

  /** Cycle the background swatch behind the model. */
  setBgIndex(index: number): void {
    const count: number = PostProcessViewModel.BG_COLORS.length;
    this.params.bgIndex = ((index % count) + count) % count;
  }

  /** Resolve the current background swatch to a hex color string. */
  backgroundColor(): string {
    return PostProcessViewModel.BG_COLORS[this.params.bgIndex];
  }

  /** Pick a model body color swatch and repaint the model's material. */
  setModelColorIndex(index: number): void {
    const count: number = PostProcessViewModel.MODEL_COLORS.length;
    this.params.modelColorIndex = ((index % count) + count) % count;
    this.applyModelColor(this.params.modelColorIndex);
    this.reglow();
  }

  /** Toggle a spin-on-its-own-axis animation loop. */
  toggleAutoRotate(on: boolean): void {
    this.params.autoRotate = on;
    if (on) {
      this.startAutoRotate();
    } else {
      this.stopAutoRotate();
    }
  }

  private startAutoRotate(): void {
    if (this.autoRotateTimer !== -1) {
      return;
    }
    this.autoRotateTimer = setInterval(() => {
      this.yaw = QuatMath.wrapAngle(this.yaw + 0.012);
      this.baseYaw = this.yaw;
      this.applyRotation();
    }, 16);
  }

  private stopAutoRotate(): void {
    if (this.autoRotateTimer !== -1) {
      clearInterval(this.autoRotateTimer);
      this.autoRotateTimer = -1;
    }
  }

  onRotateStart(): void {
    if (this.params.autoRotate) {
      this.params.autoRotate = false;
      this.stopAutoRotate();
    }
    this.baseYaw = this.yaw;
    this.basePitch = this.pitch;
  }

  onRotateUpdate(offsetX: number, offsetY: number): void {
    this.yaw = this.baseYaw + offsetX * 0.012;
    this.pitch = QuatMath.clamp(this.basePitch + offsetY * 0.012, -1.4, 1.4);
    this.applyRotation();
  }

  private applyPostProcess(): void {
    if (this.cam === null) {
      return;
    }

    const p: EffectParams = this.params;

    const tone: ToneMappingSettings = {
      type: p.toneType,
      exposure: p.exposure
    };

    const pp: PostProcessSettings = { toneMapping: tone };

    if (p.bloomOn) {
      const bloom: BloomSettings = {
        // Lowered so the glow-driven emissive body actually crosses the
        // threshold; at 1.0/2.0 nothing in this unlit GLB ever bloomed.
        thresholdHard: 0.8,
        thresholdSoft: 1.6,
        scaleFactor: 1.0,
        scatter: p.scatter
      };
      pp.bloom = bloom;
    }

    if (p.vignetteOn) {
      const vig: VignetteSettings = {
        roundness: 0.7,
        intensity: p.vignette
      };
      pp.vignette = vig;
    }

    if (p.fringeOn) {
      const cf: ColorFringeSettings = {
        intensity: p.fringe
      };
      pp.colorFringe = cf;
    }

    this.cam.postProcess = pp;
    this.renderOnce();
  }

  private reglow(): void {
    // This GLB has no marker-named nodes and no emissive materials, so drive
    // the body material's emissive from the glow slider — this is what gives
    // bloom bright pixels to scatter.
    if (this.bodyMaterial !== null) {
      const tint: Vec4 = PostProcessViewModel.hexToLinearVec4(
        PostProcessViewModel.MODEL_COLORS[this.params.modelColorIndex]);
      const s: number = this.params.glow * 0.25;
      const emissive: Vec4 = { x: tint.x * s, y: tint.y * s, z: tint.z * s, w: 1.0 };
      this.bodyMaterial.emissive.factor = emissive;
    }
    if (this.scene !== null && this.scene.root !== null) {
      this.boostEmissiveMarkers(this.scene.root, this.params.glow);
    }
    this.renderOnce();
  }

  private applyRotation(): void {
    if (this.rotateNode === null) {
      return;
    }
    const q: Quat = QuatMath.fromYawPitch(this.yaw, this.pitch);
    this.rotateNode.rotation = q;
    this.renderOnce();
  }

  private renderOnce(): void {
    if (this.scene !== null) {
      const params: RenderParameters = { alwaysRender: true };
      this.scene.renderFrame(params);
    }
  }

  private boostEmissiveMarkers(node: Node, intensity: number): void {
    if (node.nodeType === NodeType.GEOMETRY) {
      const geo: Geometry = node as Geometry;
      const subs = geo.mesh.subMeshes;
      const subsCount: number = subs.length;

      const nodeNameIsMarker: boolean = this.isMarkerName(node.name);
      // Hoisted out of the loop: this value never changes per-iteration,
      // so reading it once avoids the repeated constant property access.
      const metallicRoughnessType: MaterialType = MaterialType.METALLIC_ROUGHNESS;

      for (let i = 0; i < subsCount; i++) {
        const sub = subs[i];
        const isMarker: boolean = nodeNameIsMarker || this.isMarkerName(sub.name);
        const mat = sub.material;
        if (isMarker && mat.materialType === metallicRoughnessType) {
          const mr: MetallicRoughnessMaterial = mat as MetallicRoughnessMaterial;
          const color: Vec4 = {
            x: 1.0 * intensity,
            y: 0.84 * intensity,
            z: 0.30 * intensity,
            w: 1.0
          };
          mr.emissive.factor = color;
        }
      }
    }
    const kids = node.children;
    const n: number = kids.count();
    for (let i = 0; i < n; i++) {
      const child: Node | null = kids.get(i);
      if (child !== null) {
        this.boostEmissiveMarkers(child, intensity);
      }
    }
  }

  /** Assign our own material over every geometry mesh in the scene. The GLB has
   *  no materials of its own, so this is what makes the model recolorable. */
  private attachBodyMaterial(node: Node): void {
    if (node.nodeType === NodeType.GEOMETRY && this.bodyMaterial !== null) {
      const geo: Geometry = node as Geometry;
      geo.mesh.materialOverride = this.bodyMaterial;
      console.info(`[modelcolor] override set on "${node.name}"`);
    }

    const kids = node.children;
    const n: number = kids.count();
    for (let i = 0; i < n; i++) {
      const child: Node | null = kids.get(i);
      if (child !== null) {
        this.attachBodyMaterial(child);
      }
    }
  }

  /** Paint the whole model with the chosen swatch color. */
  private applyModelColor(index: number): void {
    if (this.bodyMaterial === null) {
      console.error('[modelcolor] no body material yet, cannot recolor');
      return;
    }
    const color: Vec4 = PostProcessViewModel.hexToLinearVec4(PostProcessViewModel.MODEL_COLORS[index]);
    try {
      this.bodyMaterial.baseColor.factor = color;
      console.info(`[modelcolor] applied index ${index} -> ${PostProcessViewModel.MODEL_COLORS[index]}`);
    } catch (e) {
      console.error(`[modelcolor] baseColor write failed: ${e}`);
    }
    this.renderOnce();
  }

  /** Convert a "#RRGGBB" string to a linear-space Vec4 for material factors. */
  private static hexToLinearVec4(hex: string): Vec4 {
    const r: number = parseInt(hex.slice(1, 3), 16) / 255;
    const g: number = parseInt(hex.slice(3, 5), 16) / 255;
    const b: number = parseInt(hex.slice(5, 7), 16) / 255;
    return {
      x: PostProcessViewModel.srgbToLinear(r),
      y: PostProcessViewModel.srgbToLinear(g),
      z: PostProcessViewModel.srgbToLinear(b),
      w: 1.0
    };
  }


  /** sRGB gamma -> linear so recolored materials match the 3D pipeline. */
  private static srgbToLinear(c: number): number {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  }

  private isMarkerName(name: string): boolean {
    const s: string = name.toLowerCase();
    return s.includes('index') || s.includes('marker') || s.includes('hour') ||
      s.includes('tick') || s.includes('hand') || s.includes('idx');
  }
}