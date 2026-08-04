import { ToneMappingType } from '@kit.ArkGraphics3D';

@ObservedV2
export class EffectParams {
  @Trace bloomOn: boolean = true;
  @Trace toneType: ToneMappingType = ToneMappingType.ACES;
  @Trace exposure: number = 1.0;
  @Trace scatter: number = 0.7;
  @Trace glow: number = 4.0;
  @Trace vignetteOn: boolean = true;
  @Trace vignette: number = 0.4;
  @Trace fringeOn: boolean = true;
  @Trace fringe: number = 0.2;

  // Camera + view state (not part of the post-process pass itself).
  @Trace zoom: number = 5.0;
  @Trace autoRotate: boolean = false;
  @Trace bgIndex: number = 0;
  @Trace modelColorIndex: number = 0;

  /** Reset every field back to its authored default. */
  reset(): void {
    this.bloomOn = true;
    this.toneType = ToneMappingType.ACES;
    this.exposure = 1.0;
    this.scatter = 0.7;
    this.glow = 4.0;
    this.vignetteOn = true;
    this.vignette = 0.4;
    this.fringeOn = true;
    this.fringe = 0.2;
    this.zoom = 5.0;
    this.autoRotate = false;
    this.bgIndex = 0;
    this.modelColorIndex = 0;
  }
}

