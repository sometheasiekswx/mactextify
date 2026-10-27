import { useEffect, useState } from "react";

const items = [
  { label: "How it works", href: "#how-it-works" },
  { label: "The app", href: "#the-app" },
  { label: "Open source", href: "#open-source" },
];

export function SectionNav() {
  const [active, setActive] = useState("");
  useEffect(() => {
    let frame = 0;
    const header = document.querySelector(".header-shell");
    const targets = items.map((item) => document.querySelector(item.href));
    const update = () => {
      frame = 0;
      const headerBottom = header?.getBoundingClientRect().bottom ?? 0;
      const anchorOffset =
        parseFloat(
          getComputedStyle(document.documentElement).scrollPaddingTop,
        ) || 0;
      const marker = Math.max(
        headerBottom + 1,
        anchorOffset + 1,
        window.innerHeight * 0.35,
      );
      let current = "";
      targets.forEach((target, index) => {
        if (!target) return;
        const rect = target.getBoundingClientRect();
        const margin =
          parseFloat(getComputedStyle(target).scrollMarginTop) || 0;
        if (rect.top - margin <= marker && rect.bottom > headerBottom)
          current = items[index].href;
      });
      setActive(current);
    };
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule);
    update();
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", schedule);
    };
  }, []);
  return (
    <nav className="section-nav" aria-label="Main navigation">
      {items.map((item) => (
        <a
          key={item.href}
          href={item.href}
          aria-current={active === item.href ? "location" : undefined}
        >
          {item.label}
        </a>
      ))}
    </nav>
  );
}
