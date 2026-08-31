import Animated, {
  interpolate,
  useAnimatedProps,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Ellipse, Path } from 'react-native-svg';

const AnimatedPath = Animated.createAnimatedComponent(Path);
const AnimatedEllipse = Animated.createAnimatedComponent(Ellipse);

/**
 * One expression per mood, drawn in a 100×100 box so it scales from a 26pt
 * track icon up to a mascot face without redrawing anything.
 *
 * These are the same numbers the animated face interpolates between, so a stop
 * icon on the track is exactly the frame the live face lands on when the knob
 * settles there.
 */
const STOPS = [0, 1, 2, 3, 4];
/** Vertical eye radius: wide-open in the middle, squeezed at both extremes. */
const EYE_RY = [5, 7, 8.5, 8, 4];
/** Mouth control-point offset. Negative frowns, positive grins. */
const MOUTH_CURVE = [-16, -9, 1, 17, 32];
/** Half the mouth's width — grins are wider than frowns. */
const MOUTH_HALF = [17, 18, 20, 22, 25];

const EYE_CX = 34;
const EYE_CY = 40;
const EYE_RX = 8.5;
const MOUTH_Y = 64;

const mouthPath = (half: number, curve: number) =>
  `M ${50 - half} ${MOUTH_Y} Q 50 ${MOUTH_Y + curve} ${50 + half} ${MOUTH_Y}`;

type StaticProps = {
  index: number;
  size: number;
  color: string;
};

/** A fixed expression. Used for the five stops sitting on the track. */
export function MoodFace({ index, size, color }: StaticProps) {
  const i = Math.max(0, Math.min(STOPS.length - 1, Math.round(index)));
  return (
    <Svg width={size} height={size} viewBox="0 0 100 100">
      <Ellipse cx={EYE_CX} cy={EYE_CY} rx={EYE_RX} ry={EYE_RY[i]} fill={color} />
      <Ellipse cx={100 - EYE_CX} cy={EYE_CY} rx={EYE_RX} ry={EYE_RY[i]} fill={color} />
      <Path
        d={mouthPath(MOUTH_HALF[i], MOUTH_CURVE[i])}
        stroke={color}
        strokeWidth={8}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
}

type LiveProps = {
  /** Continuous mood position, 0 → 4. */
  progress: SharedValue<number>;
  size: number;
  color: string;
};

/**
 * The same face, morphing continuously. Every element here is a real
 * react-native-svg host component (`RNSVGEllipse`, `RNSVGPath`), which is what
 * lets Reanimated drive them directly on the UI thread.
 */
export function MoodFaceLive({ progress, size, color }: LiveProps) {
  const eye = useAnimatedProps(() => ({
    ry: interpolate(progress.value, STOPS, EYE_RY),
  }));

  const mouth = useAnimatedProps(() => {
    const half = interpolate(progress.value, STOPS, MOUTH_HALF);
    const curve = interpolate(progress.value, STOPS, MOUTH_CURVE);
    return {
      d: `M ${50 - half} ${MOUTH_Y} Q 50 ${MOUTH_Y + curve} ${50 + half} ${MOUTH_Y}`,
    };
  });

  return (
    <Svg width={size} height={size} viewBox="0 0 100 100">
      <AnimatedEllipse
        cx={EYE_CX}
        cy={EYE_CY}
        rx={EYE_RX}
        animatedProps={eye}
        fill={color}
      />
      <AnimatedEllipse
        cx={100 - EYE_CX}
        cy={EYE_CY}
        rx={EYE_RX}
        animatedProps={eye}
        fill={color}
      />
      <AnimatedPath
        animatedProps={mouth}
        stroke={color}
        strokeWidth={8}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
}
