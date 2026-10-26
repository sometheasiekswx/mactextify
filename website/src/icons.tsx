export function Icon({
  name,
  size = 20,
}: {
  name:
    | "arrow"
    | "download"
    | "github"
    | "play"
    | "pause"
    | "copy"
    | "check"
    | "lock"
    | "file"
    | "sun"
    | "moon"
    | "refresh";
  size?: number;
}) {
  const paths = {
    arrow: (
      <>
        <path d="M5 12h14m-6-6 6 6-6 6" />
      </>
    ),
    download: (
      <>
        <path d="M12 3v12m-5-5 5 5 5-5M5 16v4h14v-4" />
      </>
    ),
    github: (
      <>
        <path
          d="M9 19c-4 1-4-2-6-2m14 5v-4a3.5 3.5 0 0 0-1-2.7c3.3-.4 6.8-1.6 6.8-7.3a5.7 5.7 0 0 0-1.5-4 5.2 5.2 0 0 0-.1-4s-1.2-.4-4.1 1.5a14 14 0 0 0-7.4 0C6.8-.4 5.6 0 5.6 0a5.2 5.2 0 0 0-.1 4A5.7 5.7 0 0 0 4 8c0 5.7 3.5 6.9 6.8 7.3A3.5 3.5 0 0 0 10 18v4"
          transform="translate(1 2) scale(.85)"
        />
      </>
    ),
    play: <path d="m9 5 11 7-11 7Z" />,
    pause: (
      <>
        <path d="M8 5v14M16 5v14" />
      </>
    ),
    copy: (
      <>
        <rect x="8" y="8" width="12" height="13" rx="2" />
        <path d="M15 8V4H4v12h4" />
      </>
    ),
    check: <path d="m5 12 4 4L19 6" />,
    lock: (
      <>
        <rect x="5" y="10" width="14" height="11" rx="3" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3m-4 4v3" />
      </>
    ),
    file: (
      <>
        <path d="M14 3H5v18h14V8Zm0 0v5h5M8 12h8m-8 4h6" />
      </>
    ),
    sun: (
      <>
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5" />
      </>
    ),
    moon: <path d="M20 14a8 8 0 0 1-10-10 8 8 0 1 0 10 10Z" />,
    refresh: (
      <>
        <path d="M20 6v5h-5M4 18v-5h5M5.5 7a8 8 0 0 1 13-1L20 9M4 15l1.5 3a8 8 0 0 0 13-1" />
      </>
    ),
  };
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {paths[name]}
    </svg>
  );
}
