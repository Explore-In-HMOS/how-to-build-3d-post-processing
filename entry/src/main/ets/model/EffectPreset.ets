import { ToneMappingType } from '@kit.ArkGraphics3D';
import { EffectParams } from './EffectParams';

/**
 * A named bundle of post-process values that can be applied to EffectParams
 * in one shot. Used to power the "one tap" look buttons in the UI.
 */
export class EffectPreset {
  readonly key: string;
  readonly label: string;
  readonly bloomOn: boolean;
  readonly toneType: ToneMappingType;
  readonly exposure: number;
  readonly scatter: number;
  readonly glow: number;
  readonly vignetteOn: boolean;
  readonly vignette: number;
  readonly fringeOn: boolean;
  readonly fringe: number;

  constructor(
    key: string,
    label: string,
    bloomOn: boolean,
    toneType: ToneMappingType,
    exposure: number,
    scatter: number,
    glow: number,
    vignetteOn: boolean,
    vignette: number,
    fringeOn: boolean,
    fringe: number
  ) {
    this.key = key;
    this.label = label;
    this.bloomOn = bloomOn;
    this.toneType = toneType;
    this.exposure = exposure;
    this.scatter = scatter;
    this.glow = glow;
    this.vignetteOn = vignetteOn;
    this.vignette = vignette;
    this.fringeOn = fringeOn;
    this.fringe = fringe;
  }

  /** Copy this preset's values onto a live EffectParams instance. */
  applyTo(params: EffectParams): void {
    params.bloomOn = this.bloomOn;
    params.toneType = this.toneType;
    params.exposure = this.exposure;
    params.scatter = this.scatter;
    params.glow = this.glow;
    params.vignetteOn = this.vignetteOn;
    params.vignette = this.vignette;
    params.fringeOn = this.fringeOn;
    params.fringe = this.fringe;
  }
}

/**
 * The catalogue of presets shown in the effect panel. Each entry is tuned to a
 * distinct mood so switching between them is visually obvious.
 */
export class PresetCatalog {
  static readonly CINEMATIC: EffectPreset = new EffectPreset(
    'preset_cinematic', 'Cinematic', true, ToneMappingType.FILMIC, 1.1, 0.75, 4.0, true, 0.55, true, 0.25
  );

  static readonly VIVID: EffectPreset = new EffectPreset(
    'preset_vivid', 'Vivid', true, ToneMappingType.ACES_2020, 1.6, 0.9, 6.0, false, 0.0, true, 0.15
  );

  static readonly NOIR: EffectPreset = new EffectPreset(
    'preset_noir', 'Noir', false, ToneMappingType.ACES, 0.7, 0.0, 1.0, true, 0.85, false, 0.0
  );

  static readonly DREAM: EffectPreset = new EffectPreset(
    'preset_dream', 'Dream', true, ToneMappingType.ACES_2020, 1.3, 1.0, 5.0, true, 0.3, true, 0.5
  );

  /** Ordered list used to render the preset buttons. */
  static all(): EffectPreset[] {
    return [
      PresetCatalog.CINEMATIC,
      PresetCatalog.VIVID,
      PresetCatalog.NOIR,
      PresetCatalog.DREAM
    ];
  }
}
