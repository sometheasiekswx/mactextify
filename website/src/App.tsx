import { useEffect, useRef, useState } from "react";
import { animate, stagger } from "animejs";
import { SectionNav } from "./components/SectionNav";
import { ExtractionDemo } from "./components/ExtractionDemo";
import { Icon } from "./icons";
import { useCopy, useReducedMotion } from "./hooks";
import { useScrollMotion } from "./useScrollMotion";
import { release, repo } from "./release";

const buildCommand = `git clone ${repo}.git\ncd mactextify\n./scripts/check-prerequisites.sh\n./scripts/build-app.sh\nopen .build/MacTextify.app`;

export function App() {
  const [theme, setTheme] = useState<"pearl" | "midnight">("pearl");
  const reduced = useReducedMotion();
  useScrollMotion(reduced);
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
      delay: stagger(110),
      duration: 1000,
      ease: "outExpo",
    });
    return () => {
      intro.revert();
    };
  }, [reduced]);
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <div className="header-shell">
        <div className="reading-progress" aria-hidden="true" />
        <header className="site-header wrap">
          <a href="#" className="brand" aria-label="MacTextify home">
            <img src="./media/app-icon.png" alt="" width="36" height="36" />
            <span>MacTextify</span>
          </a>
          <SectionNav />
          <div className="header-actions">
            <button
              className="theme-button"
              aria-label={`Switch to ${theme === "pearl" ? "Midnight" : "Pearl"} theme`}
              onClick={() => setTheme(theme === "pearl" ? "midnight" : "pearl")}
            >
              <Icon name={theme === "pearl" ? "moon" : "sun"} size={18} />
            </button>
            <a className="button button-small" href="#download">
              Download <Icon name="download" size={16} />
            </a>
          </div>
        </header>
      </div>
      <main id="main">
        <section className="hero wrap" aria-labelledby="hero-title">
          <div className="hero-heading">
            <h1 ref={headline} id="hero-title">
              <span>Text in images.</span>
              <span>
                Now <em>text files.</em>
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
              Extract words from images into text and Markdown files.
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
            A photographed page. A scanned letter. A screenshot worth keeping.
            Turn the words in your images into files you can search, edit, and
            use.
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
                alt="The real MacTextify app after extracting three synthetic text images. Each result is marked Needs Review, and text output settings are visible."
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
              key. Your images stay with you.
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
              <p>Turn the text in your images into files you can use.</p>
            </div>
            <div className="download-panel">
              <h3>MacTextify for Mac</h3>
              {release.available ? (
                <>
                  <p className="release-meta">
                    Version {release.version} · macOS 14+ · Free & open source
                  </p>
                  <p className="release-note release-warning">
                    <strong>Unsigned download.</strong> Not Developer ID signed
                    or notarized by Apple. macOS may block the first launch; see
                    installation instructions below.
                  </p>
                  <p className="release-note">
                    Choose Apple silicon for an M-series chip, Intel for an
                    Intel processor, or Universal for either. Find yours in
                    Apple menu → About This Mac.
                  </p>
                  {("assets" in release
                    ? release.assets
                    : [
                        {
                          ...release,
                          url: `./downloads/${release.file}`,
                          checksumURL: `./downloads/${release.file}.sha256`,
                        },
                      ]
                  ).map((asset) => (
                    <div
                      key={asset.architecture}
                      className="architecture-download"
                    >
                      <a className="button download-primary" href={asset.url}>
                        <Icon name="download" />{" "}
                        {asset.architecture === "arm64"
                          ? "Apple silicon"
                          : asset.architecture === "x86_64"
                            ? "Intel"
                            : "Universal"}
                        <span>
                          {(asset.bytes / 1024 / 1024).toFixed(1)} MB ZIP
                        </span>
                      </a>
                      <details className="checksum">
                        <summary>
                          Verify{" "}
                          {asset.architecture === "arm64"
                            ? "Apple silicon"
                            : asset.architecture === "x86_64"
                              ? "Intel"
                              : "Universal"}{" "}
                          download
                        </summary>
                        <p>SHA-256</p>
                        <code>{asset.sha256}</code>
                        <a href={asset.checksumURL}>Download checksums</a>
                        <p>
                          In Terminal, run{" "}
                          <code>shasum -a 256 ~/Downloads/{asset.file}</code>{" "}
                          and compare the result above.
                        </p>
                      </details>
                    </div>
                  ))}
                  <details className="install-details" open>
                    <summary>How to install MacTextify</summary>
                    <ol>
                      <li>
                        Download your chosen ZIP and double-click it to unzip.
                      </li>
                      <li>Move MacTextify.app to Applications.</li>
                      <li>
                        Open MacTextify. If macOS blocks it, dismiss the alert.
                        If you trust this download, open System Settings →
                        Privacy & Security, scroll to Security, and click Open
                        Anyway for MacTextify. Confirm Open and authenticate if
                        asked. See{" "}
                        <a href="https://support.apple.com/en-au/102445">
                          Apple’s app-specific opening instructions
                        </a>
                        .
                      </li>
                    </ol>
                    <p>
                      Live Text availability depends on your hardware and OS.
                      Review extracted text for accuracy.
                    </p>
                  </details>
                  <p className="release-note">
                    Built from{" "}
                    <a href={`${repo}/commit/${release.sourceRevision}`}>
                      {release.sourceRevision.slice(0, 7)}
                    </a>
                    .{" "}
                    <a href={`${repo}/releases/tag/v${release.version}`}>
                      Release notes
                    </a>
                    . No Xcode required.
                  </p>
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
                OCR runs on your Mac. Updater-enabled versions contact the
                release server only for manual or opted-in update checks. OCR
                uses Apple’s on-device frameworks. The website demonstration
                uses fixed sample content and does not upload or process your
                files.
              </p>
            </details>
            <details>
              <summary>Which images can I use?</summary>
              <p>
                Photos, scans, screenshots, and other images containing text,
                saved as PNG or JPEG. Add individual images or folders,
                including subfolders. Convert other formats to PNG or JPEG
                first. OCR can misread characters and line order; review names,
                numbers, and other important details.
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
