import { useEffect, useState } from "react";

export function useReducedMotion() {
  const [reduce, setReduce] = useState(
    () => window.matchMedia("(prefers-reduced-motion: reduce)").matches,
  );
  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    const change = () => setReduce(query.matches);
    query.addEventListener("change", change);
    return () => query.removeEventListener("change", change);
  }, []);
  return reduce;
}

export function useCopy() {
  const [status, setStatus] = useState("");
  async function copy(value: string) {
    try {
      await navigator.clipboard.writeText(value);
      setStatus("Copied");
    } catch {
      setStatus("Select the text to copy");
    }
  }
  useEffect(() => {
    if (!status) return;
    const id = window.setTimeout(() => setStatus(""), 3500);
    return () => clearTimeout(id);
  }, [status]);
  return { status, copy };
}
