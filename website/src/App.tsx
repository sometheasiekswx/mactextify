import { useEffect, useRef, useState } from "react";
import { animate, stagger, onScroll } from "animejs";
import { SpotlightNav } from "./components/SpotlightNav";
import { ExtractionDemo } from "./components/ExtractionDemo";
import { Icon } from "./icons";
import { useCopy, useReducedMotion } from "./hooks";
import { release, repo } from "./release";

const buildCommand = `git clone ${repo}.git\ncd mactextify\n./scripts/check-prerequisites.sh\n./scripts/build-app.sh\nopen .build/MacTextify.app`;

export function App() {
  const [theme, setTheme] = useState<"pearl" | "midnight">("pearl");
  const reduced = useReducedMotion();
  const headline = useRef<HTMLHeadingElement>(null);
  const { copy, status } = useCopy();
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute("content", theme === "midnight" ? "#181a18" : "#f4f3ef");
  }, [theme]);
  useEffect(() => {
    if (reduced || !headline.current) return;
    const intro = animate(headline.current.children, {
      translateY: [22, 0],
      opacity: [0.45, 1],
      delay: stagger(110),
      duration: 1000,
      ease: "outExpo",
    });
    return () => {
      intro.revert();
    };
  }, [reduced]);
  useEffect(() => {
    if (reduced) return;
    const capture = document.querySelector(".native-capture");
    if (!capture) return;
    const observer = onScroll({
      target: ".app-section",
      enter: "bottom bottom",
      leave: "top top",
      sync: 0.4,
    });
    const motion = animate(capture, {
      translateY: [26, -14],
      ease: "linear",
      autoplay: observer,
    });
    return () => {
      motion.revert();
      observer.revert();
    };
  }, [reduced]);
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <header className="site-header wrap">
        <a href="#" className="brand" aria-label="MacTextify home">
          <img src="./media/app-icon.png" alt="" width="36" height="36" />
          <span>MacTextify</span>
        </a>
        <SpotlightNav />
        <div className="header-actions">
          <button
            className="theme-button"
            aria-label={`Switch to ${theme === "pearl" ? "Midnight" : "Pearl"} theme`}
            onClick={() => setTheme(theme === "pearl" ? "midnight" : "pearl")}
          >
            <Icon name={theme === "pearl" ? "moon" : "sun"} size={18} />
          </button>
          <a className="button button-small" href="#download">
            Get MacTextify <Icon name="download" size={16} />
          </a>
        </div>
      </header>
      <main id="main">
        <section className="hero wrap" aria-labelledby="hero-title">
          <div className="hero-heading">
            <h1 ref={headline} id="hero-title">
              <span>Your screenshots.</span>
              <span>
                Now <em>searchable.</em>
              </span>
            </h1>
            <div className="hero-intro">
              <p>
                Keep the words.
                <br />
                Leave the retyping behind.
              </p>
              <span>Made for macOS. Free & open source.</span>
            </div>
          </div>
          <div className="hero-action-row">
            <p>
              Turn images into text you can search, copy, and keep.
              <br className="desktop-break" /> All on your Mac. All yours.
            </p>
            <div className="hero-buttons">
              <a className="button" href="#download">
                <Icon name="download" />
                {release.available ? "Download for Mac" : "Get MacTextify"}
              </a>
              <a className="text-link" href={repo}>
                <Icon name="github" size={18} /> View on GitHub{" "}
                <Icon name="arrow" size={16} />
              </a>
            </div>
          </div>
          <ExtractionDemo />
          <div className="fact-line">
            <span>
              <Icon name="lock" size={15} /> On-device Apple OCR
            </span>
            <span>PNG + JPEG</span>
            <span>Text + Markdown</span>
            <span>macOS 14+</span>
          </div>
        </section>

        <section className="intro-section wrap" aria-labelledby="words-title">
          <h2 id="words-title">
            You saved it for a reason.
            <br />
            <span>Make it useful again.</span>
          </h2>
          <p>
            A meeting recap. A passage worth keeping. That screenshot you knew
            you’d need later. Give those words a life beyond the image.
          </p>
        </section>

        <section
          className="app-section"
          id="the-app"
          aria-labelledby="app-title"
        >
          <div className="wrap app-layout">
            <div className="app-story">
              <h2 id="app-title">
                A little app.
                <br />A lot less
                <br />
                <em>busywork.</em>
              </h2>
              <p>
                Drop in a few images or a whole folder. Choose where the text
                goes. Let your Mac take it from there.
              </p>
              <ol className="workflow">
                <li>
                  <span>1</span>
                  <div>
                    <h3>Add your images</h3>
                    <p>Drag in PNGs, JPEGs, or folders.</p>
                  </div>
                </li>
                <li>
                  <span>2</span>
                  <div>
                    <h3>Choose your output</h3>
                    <p>Plain text or Markdown. Your location.</p>
                  </div>
                </li>
                <li>
                  <span>3</span>
                  <div>
                    <h3>Extract, review, use</h3>
                    <p>Open your exports and keep going.</p>
                  </div>
                </li>
              </ol>
              <a href="#download" className="text-link">
                Make room for the useful words <Icon name="arrow" size={18} />
              </a>
            </div>
            <figure className="native-capture">
              <img
                src="./media/native-app.png"
                width="1088"
                height="1440"
                alt="The real MacTextify app after extracting three synthetic screenshots. Each result is marked Needs Review, and text output settings are visible."
                loading="lazy"
              />
              <figcaption>
                Actual MacTextify app · synthetic sample documents
              </figcaption>
            </figure>
          </div>
        </section>

        <section className="principles wrap" aria-label="Why MacTextify">
          <div className="privacy-statement">
            <div className="privacy-symbol" aria-hidden="true">
              <Icon name="lock" size={50} />
            </div>
            <h2>
              Your words.
              <br />
              Your Mac.
              <br />
              <em>Full stop.</em>
            </h2>
            <p>
              Apple OCR works on your device. No uploads, no account, no API
              key. Your screenshots stay with you.
            </p>
          </div>
          <div className="principle-details">
            <article>
              <h3>Files you can do things with.</h3>
              <p>
                Copy a quote. Search your notes. Build your own archive. Export
                everyday text or Markdown, with an index to find your way back.
              </p>
              <div className="file-output" aria-hidden="true">
                <span>
                  <Icon name="file" />
                  Meeting recap.txt
                </span>
                <span>
                  <Icon name="file" />
                  Project notes.md
                </span>
                <span>
                  <Icon name="file" />
                  index.md
                </span>
              </div>
            </article>
            <article>
              <h3>Your originals stay original.</h3>
              <p>
                The app leaves source images in place, protects edited exports,
                and saves progress for recovery. Review the words before relying
                on them.
              </p>
              <a
                className="inline-link"
                href={`${repo}/blob/main/docs/cli.md#safety-and-recovery`}
              >
                How recovery works <Icon name="arrow" size={16} />
              </a>
            </article>
          </div>
        </section>

        <section
          className="download-section"
          id="download"
          aria-labelledby="download-title"
        >
          <div className="wrap download-layout">
            <div className="download-heading">
              <img
                src="./media/app-icon.png"
                width="100"
                height="100"
                alt=""
                loading="lazy"
              />
              <h2 id="download-title">
                Less retyping.
                <br />
                More <em>doing.</em>
              </h2>
              <p>Make your screenshots work for you.</p>
            </div>
            <div className="download-panel">
              <h3>MacTextify for Mac</h3>
              {release.available ? (
                <>
                  <p className="release-meta">
                    Version {release.version} ·{" "}
                    {release.architecture === "arm64"
                      ? "Apple silicon"
                      : release.architecture === "x86_64"
                        ? "Intel"
                        : "Universal"}{" "}
                    · macOS 14+
                    <br />
                    {(release.bytes / 1024 / 1024).toFixed(1)} MB ZIP
                  </p>
                  <p className="release-note release-warning">
                    <strong>Unsigned preview.</strong> This build isn’t
                    Developer ID signed or notarized by Apple. macOS may block
                    it on first launch.
                  </p>
                  <a
                    className="button download-primary"
                    href={`./downloads/${release.file}`}
                    download
                  >
                    <Icon name="download" /> Download preview{" "}
                    <Icon name="arrow" />
                  </a>
                  <details className="install-details">
                    <summary>How to install this preview</summary>
                    <ol>
                      <li>Download and unzip the archive.</li>
                      <li>Move MacTextify.app to Applications.</li>
                      <li>
                        Open the app. If macOS blocks it and you trust this
                        download, follow{" "}
                        <a href="https://support.apple.com/en-au/102445">
                          Apple’s app-specific opening instructions
                        </a>{" "}
                        in Privacy & Security.
                      </li>
                    </ol>
                    <p>
                      Live Text availability depends on your hardware and OS.
                      Review extracted text for accuracy.
                    </p>
                  </details>
                  <details className="checksum">
                    <summary>Verify the download</summary>
                    <p>SHA-256</p>
                    <code>{release.sha256}</code>
                    <a href={`./downloads/${release.file}.sha256`} download>
                      Download checksum
                    </a>
                    <p>
                      Built from source revision{" "}
                      <a href={`${repo}/commit/${release.sourceRevision}`}>
                        {release.sourceRevision.slice(0, 7)}
                      </a>
                      .
                    </p>
                  </details>
                </>
              ) : (
                <>
                  <p className="release-meta">macOS 14+ · Free & open source</p>
                  <p className="release-note">
                    A prebuilt app download isn’t available yet. You can build
                    MacTextify from the source with full Xcode and Swift 5.9+.
                  </p>
                  <a
                    className="button download-primary"
                    href={`${repo}#quick-start`}
                  >
                    Build from source <Icon name="arrow" />
                  </a>
                </>
              )}
              <p className="source-alternative">
                Prefer to build it yourself?{" "}
                <a href={`${repo}#quick-start`}>
                  Get the source <Icon name="arrow" size={14} />
                </a>
              </p>
            </div>
          </div>
        </section>

        <section
          className="open-source wrap"
          id="open-source"
          aria-labelledby="source-title"
        >
          <div>
            <h2 id="source-title">
              Open source.
              <br />
              Open to <em>your ideas.</em>
            </h2>
            <p>
              Small tools get better when people care about the details. Read
              the code, report a rough edge, or make MacTextify a little more
              useful.
            </p>
            <div className="contribution-links">
              <a className="button" href={repo}>
                <Icon name="github" /> Explore the source
              </a>
              <a
                className="text-link"
                href={`${repo}/blob/main/CONTRIBUTING.md`}
              >
                Start contributing <Icon name="arrow" size={18} />
              </a>
            </div>
          </div>
          <div className="terminal">
            <div className="terminal-header">
              <span>Build it on your Mac</span>
              <button
                aria-label="Copy build commands"
                onClick={() => copy(buildCommand)}
              >
                <Icon name={status === "Copied" ? "check" : "copy"} size={16} />
                <span>{status || "Copy"}</span>
              </button>
            </div>
            <pre>
              <code>{buildCommand}</code>
            </pre>
            <p>
              Requires full Xcode + Swift 5.9+.{" "}
              <a href={`${repo}/blob/main/docs/distribution.md`}>
                Build requirements <Icon name="arrow" size={14} />
              </a>
            </p>
            <span className="sr-only" role="status">
              {status}
            </span>
          </div>
        </section>

        <section className="faq wrap" aria-labelledby="faq-title">
          <h2 id="faq-title">A few useful details.</h2>
          <div>
            <details>
              <summary>Does anything leave my Mac?</summary>
              <p>
                The native app makes no application network requests. OCR uses
                Apple’s on-device frameworks. The website demonstration uses
                fixed sample content and does not upload or process your files.
              </p>
            </details>
            <details>
              <summary>Which images can I use?</summary>
              <p>
                PNG and JPEG images, individually or in folders. You can include
                subfolders. OCR can misread characters and line order; review
                names, numbers, and other important details.
              </p>
            </details>
            <details>
              <summary>Can I use the terminal instead?</summary>
              <p>
                Yes. MacTextify includes a command-line tool with additional
                language, layout, and archival options.{" "}
                <a href={`${repo}/blob/main/docs/cli.md`}>
                  Read the CLI guide.
                </a>
              </p>
            </details>
            <details>
              <summary>Is MacTextify free?</summary>
              <p>
                Yes. The source is available under the MIT license. No account
                or subscription is required.
              </p>
            </details>
          </div>
        </section>
      </main>
      <footer className="site-footer wrap">
        <a className="brand" href="#">
          <img src="./media/app-icon.png" width="30" height="30" alt="" />
          <span>MacTextify</span>
        </a>
        <span>Keep the words. Keep your workflow.</span>
        <div>
          <a href={`${repo}/blob/main/LICENSE`}>MIT license</a>
          <a href={`${repo}/issues`}>Report an issue</a>
          <a href={repo}>
            GitHub <Icon name="arrow" size={14} />
          </a>
        </div>
      </footer>
    </>
  );
}
