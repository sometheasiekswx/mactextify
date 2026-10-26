// Adapted from Vengeance UI Spotlight Navbar (MIT, Ashutoshx7).
// See THIRD_PARTY_NOTICES.md for source, hash and license.
import { useEffect, useRef } from "react";
import { animate, spring } from "animejs";
import { useReducedMotion } from "../hooks";

const items = [
  { label: "How it works", href: "#how-it-works" },
  { label: "The app", href: "#the-app" },
  { label: "Open source", href: "#open-source" },
];

export function SpotlightNav() {
  const nav = useRef<HTMLElement>(null);
  const animation = useRef<ReturnType<typeof animate> | null>(null);
  const position = useRef({ x: 70 });
  const reduced = useReducedMotion();
  function point(x: number, direct = false) {
    animation.current?.pause();
    const update = () =>
      nav.current?.style.setProperty(
        "--spotlight-x",
        `${position.current.x}px`,
      );
    if (direct || reduced) {
      position.current.x = x;
      update();
      return;
    }
    animation.current = animate(position.current, {
      x,
      ease: spring({ stiffness: 200, damping: 28 }),
      onUpdate: update,
    });
  }
  useEffect(
    () => () => {
      animation.current?.revert();
    },
    [],
  );
  return (
    <nav
      ref={nav}
      className="spotlight-nav"
      aria-label="Main navigation"
      onPointerMove={(e) =>
        point(e.clientX - e.currentTarget.getBoundingClientRect().left, true)
      }
      onPointerLeave={() => point(70)}
    >
      <span className="nav-light" aria-hidden="true" />
      {items.map((item) => (
        <a
          key={item.href}
          href={item.href}
          onFocus={(e) =>
            point(e.currentTarget.offsetLeft + e.currentTarget.offsetWidth / 2)
          }
        >
          {item.label}
        </a>
      ))}
    </nav>
  );
}
