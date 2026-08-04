import { ToneMappingType } from '@kit.ArkGraphics3D';
import { PostProcessViewModel } from '../viewmodel/PostProcessViewModel';
import { EffectPreset, PresetCatalog } from '../model/EffectPreset';

@Entry
@ComponentV2
struct Index {
  @Local vm: PostProcessViewModel = new PostProcessViewModel();
  @Local panelOpen: boolean = false;

  onPageShow(): void {
    this.vm.initScene();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.vm.sceneOption) {
        Component3D(this.vm.sceneOption)
          .renderWidth('100%')
          .renderHeight('100%')
      }

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .gesture(
          PanGesture()
            .onActionStart(() => {
              this.vm.onRotateStart();
            })
            .onActionUpdate((e: GestureEvent) => {
              this.vm.onRotateUpdate(e.offsetX, e.offsetY);
            })
        )

      if (this.panelOpen) {
        this.EffectPanel()
      }

      Button(this.panelOpen ? $r('app.string.btn_effects_close') : $r('app.string.btn_effects_open'))
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('rgba(0,0,0,0.55)')
        .borderRadius(20)
        .padding({ left: 18, right: 18, top: 8, bottom: 8 })
        .position({ right: 16, top: 40 })
        .onClick(() => {
          this.panelOpen = !this.panelOpen;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.vm.backgroundColor())
  }

  @Builder
  EffectPanel() {
    Scroll() {
      Column({ space: 10 }) {
      Text($r('app.string.section_presets')).fontColor('#FFD54A').fontSize(13).width('100%')
      Row({ space: 8 }) {
        ForEach(PresetCatalog.all(), (preset: EffectPreset) => {
          this.PresetBtn(preset);
        }, (preset: EffectPreset) => preset.key)
      }.width('100%')

      Divider().color('rgba(255,255,255,0.15)').width('100%')

      Row() {
        Text($r('app.string.effect_bloom_glow')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.vm.params.bloomOn })
          .onChange((on: boolean) => {
            this.vm.setBloomOn(on);
          })
      }.width('100%')

      Text($r('app.string.effect_tone_mapping')).fontColor(Color.White).fontSize(15).width('100%')
      Row({ space: 8 }) {
        this.ToneBtn($r('app.string.tone_aces'), ToneMappingType.ACES)
        this.ToneBtn($r('app.string.tone_aces_2020'), ToneMappingType.ACES_2020)
        this.ToneBtn($r('app.string.tone_filmic'), ToneMappingType.FILMIC)
      }.width('100%')

      Text($r('app.string.effect_exposure', this.vm.params.exposure.toFixed(2))).fontColor(Color.White).fontSize(14).width('100%')
      Slider({ value: this.vm.params.exposure, min: 0.2, max: 3.0, step: 0.05 })
        .onChange((v: number) => {
          this.vm.setExposure(v);
        })

      Text($r('app.string.effect_bloom_scatter', this.vm.params.scatter.toFixed(2))).fontColor(Color.White).fontSize(14).width('100%')
      Slider({ value: this.vm.params.scatter, min: 0, max: 1.0, step: 0.05 })
        .enabled(this.vm.params.bloomOn)
        .onChange((v: number) => {
          this.vm.setScatter(v);
        })

      Row() {
        Text($r('app.string.effect_vignette')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.vm.params.vignetteOn })
          .onChange((on: boolean) => {
            this.vm.setVignetteOn(on);
          })
      }.width('100%')
      Slider({ value: this.vm.params.vignette, min: -1.0, max: 1.0, step: 0.05 })
        .enabled(this.vm.params.vignetteOn)
        .onChange((v: number) => {
          this.vm.setVignette(v);
        })

      Row() {
        Text($r('app.string.effect_color_fringe')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.vm.params.fringeOn })
          .onChange((on: boolean) => {
            this.vm.setFringeOn(on);
          })
      }.width('100%')
      Slider({ value: this.vm.params.fringe, min: 0, max: 1.0, step: 0.05 })
        .enabled(this.vm.params.fringeOn)
        .onChange((v: number) => {
          this.vm.setFringe(v);
        })

      Text($r('app.string.effect_index_glow', this.vm.params.glow.toFixed(1))).fontColor(Color.White).fontSize(14).width('100%')
      Slider({ value: this.vm.params.glow, min: 0, max: 8.0, step: 0.5 })
        .onChange((v: number) => {
          this.vm.setGlow(v);
        })

      Divider().color('rgba(255,255,255,0.15)').width('100%')

      Text($r('app.string.section_view')).fontColor('#FFD54A').fontSize(13).width('100%')

      Text($r('app.string.view_zoom', this.vm.params.zoom.toFixed(1))).fontColor(Color.White).fontSize(14).width('100%')
      Slider({ value: this.vm.params.zoom, min: 2.0, max: 12.0, step: 0.2, reverse: true })
        .onChange((v: number) => {
          this.vm.setZoom(v);
        })

      Row() {
        Text($r('app.string.view_auto_rotate')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.vm.params.autoRotate })
          .onChange((on: boolean) => {
            this.vm.toggleAutoRotate(on);
          })
      }.width('100%')

      Row() {
        Text($r('app.string.effect_model_color')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Row({ space: 8 }) {
          this.ModelSwatch(0)
          this.ModelSwatch(1)
          this.ModelSwatch(2)
          this.ModelSwatch(3)
          this.ModelSwatch(4)
        }
      }.width('100%')

      Row() {
        Text($r('app.string.view_background')).fontColor(Color.White).fontSize(15).layoutWeight(1)
        Row({ space: 8 }) {
          this.BgSwatch(0)
          this.BgSwatch(1)
          this.BgSwatch(2)
          this.BgSwatch(3)
        }
      }.width('100%')

      Button($r('app.string.btn_reset'))
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('rgba(255,255,255,0.15)')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 4 })
        .onClick(() => {
          this.vm.resetDefaults();
        })
      }
      .width('100%')
      .padding(16)
    }
    .width('92%')
    .constraintSize({ maxHeight: '65%' })
    .margin({ bottom: 24 })
    .borderRadius(20)
    .backgroundColor('rgba(0,0,0,0.55)')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  PresetBtn(preset: EffectPreset) {
    Text(preset.label)
      .fontSize(13)
      .fontColor(Color.White)
      .backgroundColor('rgba(255,255,255,0.15)')
      .textAlign(TextAlign.Center)
      .borderRadius(10)
      .padding({ top: 8, bottom: 8 })
      .layoutWeight(1)
      .onClick(() => {
        this.vm.applyPreset(preset);
      })
  }

  @Builder
  ModelSwatch(index: number) {
    Column()
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(PostProcessViewModel.MODEL_COLORS[index])
      .borderWidth(this.vm.params.modelColorIndex === index ? 2 : 1)
      .borderColor(this.vm.params.modelColorIndex === index ? '#FFD54A' : 'rgba(255,255,255,0.4)')
      .onClick(() => {
        this.vm.setModelColorIndex(index);
      })
  }

  @Builder
  BgSwatch(index: number) {
    Column()
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(PostProcessViewModel.BG_COLORS[index])
      .borderWidth(this.vm.params.bgIndex === index ? 2 : 1)
      .borderColor(this.vm.params.bgIndex === index ? '#FFD54A' : 'rgba(255,255,255,0.4)')
      .onClick(() => {
        this.vm.setBgIndex(index);
      })
  }

  @Builder
  ToneBtn(label: ResourceStr, type: ToneMappingType) {
    Text(label)
      .fontSize(13)
      .fontColor(this.vm.params.toneType === type ? Color.Black : Color.White)
      .backgroundColor(this.vm.params.toneType === type ? '#FFD54A' : 'rgba(255,255,255,0.15)')
      .textAlign(TextAlign.Center)
      .borderRadius(10)
      .padding({ top: 8, bottom: 8 })
      .layoutWeight(1)
      .onClick(() => {
        this.vm.setToneType(type);
      })
  }
}
