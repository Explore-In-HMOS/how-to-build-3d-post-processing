/** Plain quaternion shape, structurally compatible with Node.rotation. */
export interface Quat {
  x: number;
  y: number;
  z: number;
  w: number;
}

/**
 * Small quaternion / angle helpers used by the scene rotation logic.
 * Kept free of any scene state so the math stays unit-testable.
 */
export class QuatMath {
  static readonly DEG2RAD: number = Math.PI / 180;

  /** Clamp a value into the inclusive [min, max] range. */
  static clamp(value: number, min: number, max: number): number {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  /** Linear interpolation between a and b by t in [0, 1]. */
  static lerp(a: number, b: number, t: number): number {
    return a + (b - a) * QuatMath.clamp(t, 0, 1);
  }

  static degToRad(deg: number): number {
    return deg * QuatMath.DEG2RAD;
  }

  /**
   * Build a quaternion from a yaw (around Y) then pitch (around X) rotation.
   * Mirrors the hand-rolled math the view model used inline.
   */
  static fromYawPitch(yaw: number, pitch: number): Quat {
    const cy: number = Math.cos(yaw / 2);
    const sy: number = Math.sin(yaw / 2);
    const cx: number = Math.cos(pitch / 2);
    const sx: number = Math.sin(pitch / 2);
    return {
      x: cy * sx,
      y: sy * cx,
      z: -sy * sx,
      w: cy * cx
    };
  }

  /** Wrap an angle (radians) into the (-PI, PI] range so it never overflows. */
  static wrapAngle(angle: number): number {
    let a: number = angle;
    while (a > Math.PI) {
      a -= Math.PI * 2;
    }
    while (a <= -Math.PI) {
      a += Math.PI * 2;
    }
    return a;
  }
}
