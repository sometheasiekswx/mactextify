import { useEffect } from "react";
import { animate, onScroll } from "animejs";

/** Scroll owns the playhead; no hidden content or independent ambient loops. */
export function useScrollMotion(reduced: boolean) {
  useEffect(() => {
    if (reduced) return;
    const cleanups: (() => void)[] = [];
    function link(
      selector: string,
      properties: Parameters<typeof animate>[1],
      target?: string,
      enter = "bottom top",
      leave = "center center",
    ) {
      document.querySelectorAll<HTMLElement>(selector).forEach((element) => {
        const observer = onScroll({
          target: target ?? element,
          enter,
          leave,
          sync: true,
        });
        const motion = animate(element, {
          ...properties,
          ease: "linear",
          autoplay: observer,
        });
        cleanups.push(() => {
          motion.revert();
          observer.revert();
        });
      });
    }
    link(
      ".reading-progress",
      { scaleX: [0, 1] },
      "main",
      "top top",
      "bottom bottom",
    );
    link(".intro-section h2", { translateY: [30, 0] });
    link(".workflow li", { translateY: [22, 0] });
    link(
      ".native-capture",
      { translateY: [32, -20], scale: [0.94, 1] },
      ".app-section",
      "bottom top",
      "top bottom",
    );
    link(".privacy-symbol", { rotate: [-12, 0], scale: [0.85, 1] });
    link(".file-output span", { translateY: [28, 0] });
    link(".download-heading > img", { translateY: [24, 0], rotate: [-8, 0] });
    link(".terminal", { translateY: [28, 0] });
    return () => cleanups.reverse().forEach((cleanup) => cleanup());
  }, [reduced]);
}
