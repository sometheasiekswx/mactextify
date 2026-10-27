import { useEffect, useRef, useState, type CSSProperties } from "react";
import { animate, createTimeline, stagger } from "animejs";
import { useCopy, useReducedMotion } from "../hooks";
import { Icon } from "../icons";

const lines = [
  "PROJECT NOTES",
  "A calmer workspace",
  "Keep the useful words.",
  "Leave the originals untouched.",
  "Next step: turn ideas into action.",
];

export function ExtractionDemo() {
  const root = useRef<HTMLDivElement>(null);
  const clock = useRef({ value: 0 });
  const player = useRef<ReturnType<typeof animate> | null>(null);
  const [progress, setProgress] = useState(100);
  const [playing, setPlaying] = useState(false);
  const [format, setFormat] = useState<"text" | "markdown">("text");
  const { status, copy } = useCopy();
  const reduced = useReducedMotion();

  useEffect(() => {
    const motion = animate(clock.current, {
      value: [0, 100],
      duration: 3800,
      ease: "linear",
      autoplay: false,
      onUpdate: () => setProgress(clock.current.value),
      onComplete: () => setPlaying(false),
    });
    player.current = motion;
    if (reduced) {
      motion.seek(3800);
      setProgress(100);
      setPlaying(false);
    }
    const pause = () => {
      motion.pause();
      setPlaying(false);
    };
    let introduced = false;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) pause();
        else if (!introduced && !reduced) {
          introduced = true;
          motion.play();
          setPlaying(true);
        }
      },
      { threshold: 0.25 },
    );
    if (root.current) observer.observe(root.current);
    const hidden = () => {
      if (document.hidden) pause();
    };
    document.addEventListener("visibilitychange", hidden);
    return () => {
      motion.revert();
      observer.disconnect();
      document.removeEventListener("visibilitychange", hidden);
    };
  }, [reduced]);

  useEffect(() => {
    if (reduced || !root.current) return;
    const tl = createTimeline({
      defaults: { ease: "outExpo", duration: 1100 },
    });
    tl.add(root.current.querySelectorAll(".paper-back"), {
      translateY: [25, 0],
      rotate: (_, i) => (i ? 5 : -5),
      opacity: [0, 1],
      delay: stagger(100),
    });
    return () => {
      tl.revert();
    };
  }, [reduced]);

  const toggle = () => {
    if (reduced) {
      player.current?.seek(3800);
      setProgress(100);
      return;
    }
    if (playing) {
      player.current?.pause();
      setPlaying(false);
    } else {
      if (progress >= 99.9) player.current?.seek(0);
      player.current?.play();
      setPlaying(true);
    }
  };
  const scrub = (value: number) => {
    player.current?.pause();
    setPlaying(false);
    player.current?.seek(value * 38);
    setProgress(value);
  };
  const outputLines = lines.map((line, i) =>
    format === "markdown" && i === 1 ? `# ${line}` : line,
  );
  const output = outputLines.join("\n\n");
  return (
    <div
      className={`demo ${playing ? "demo-playing" : ""}`}
      ref={root}
      id="how-it-works"
      style={{ "--progress": progress / 100 } as CSSProperties}
    >
      <div className="demo-topline">
        <span>An image goes in.</span>
        <span>Useful words come out.</span>
      </div>
      <div className="demo-stage">
        <div className="source-stack">
          <div className="paper-back paper-back-one" aria-hidden="true" />
          <div className="paper-back paper-back-two" aria-hidden="true" />
          <div className="source-paper">
            <div className="file-bar">
              <Icon name="file" size={16} />
              <span>Project notes.png</span>
              <span className="file-type">IMAGE</span>
            </div>
            <div
              className="source-content"
              aria-label="Sample image: project notes"
            >
              <img
                src="./media/sample-project.png"
                alt="Project notes. A calmer workspace. Keep the useful words. Leave the originals untouched. Next step: turn ideas into action."
                width="2400"
                height="1600"
              />
              <div className="scan-line" aria-hidden="true" />
            </div>
          </div>
        </div>
        <div className="conversion" aria-hidden="true">
          <div className="conversion-rule" />
          <img src="./media/app-icon.png" alt="" width="64" height="64" />
          <div className="conversion-rule" />
          <span>On your Mac</span>
        </div>
        <div className="result-paper">
          <div className="file-bar">
            <Icon name="file" size={16} />
            <span>Project notes.{format === "text" ? "txt" : "md"}</span>
            <span
              role="img"
              aria-label={
                progress >= 99.9 ? "Sample complete" : "Sample in progress"
              }
            >
              <Icon name={progress >= 99.9 ? "check" : "file"} size={16} />
            </span>
          </div>
          <div
            className="result-body"
            role="group"
            aria-label="Sample extracted text"
          >
            {outputLines.map((line, i) => (
              <p
                key={line}
                aria-hidden={progress < i * 15 + 10}
                className={`result-line result-line-${i}`}
                style={{
                  opacity: progress >= i * 15 + 10 ? 1 : 0,
                  transform: reduced
                    ? "none"
                    : `translate(${progress >= i * 15 + 10 ? 0 : -14}px, ${progress >= i * 15 + 10 ? 0 : 5}px)`,
                }}
              >
                {line}
              </p>
            ))}
            <span
              className="result-caret"
              aria-hidden="true"
              style={{ opacity: playing ? 1 : 0 }}
            />
          </div>
          <div className="result-bottom">
            <span>Editable. Searchable. Yours.</span>
            <button
              disabled={progress < 99.9}
              onClick={() => copy(output)}
              aria-label="Copy sample text"
            >
              <Icon name={status === "Copied" ? "check" : "copy"} size={16} />
            </button>
          </div>
        </div>
      </div>
      <div className="demo-controls">
        <button className="play-button" onClick={toggle}>
          <Icon
            name={
              reduced
                ? "check"
                : playing
                  ? "pause"
                  : progress >= 99.9
                    ? "refresh"
                    : "play"
            }
            size={16}
          />
          <span>
            {reduced
              ? "Text revealed"
              : playing
                ? "Pause demo"
                : progress >= 99.9
                  ? "Replay demo"
                  : "Play the demo"}
          </span>
        </button>
        <label className="timeline">
          <span className="sr-only">Extraction demo progress</span>
          <input
            type="range"
            min="0"
            max="100"
            value={Math.round(progress)}
            onChange={(e) => scrub(Number(e.target.value))}
            aria-valuetext={`${Math.round(progress)} percent`}
          />
        </label>
        <div className="format-picker" aria-label="Sample output format">
          <button
            aria-pressed={format === "text"}
            onClick={() => setFormat("text")}
          >
            .txt
          </button>
          <button
            aria-pressed={format === "markdown"}
            onClick={() => setFormat("markdown")}
          >
            .md
          </button>
        </div>
      </div>
      <div className="demo-caption">
        <span>
          Interactive illustration · sample content · no files uploaded
        </span>
        <span role="status">{status}</span>
        <a href="#the-app">
          See the real app <Icon name="arrow" size={14} />
        </a>
      </div>
    </div>
  );
}
