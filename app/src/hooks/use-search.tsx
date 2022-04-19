import Fuse from "fuse.js";
import { useEffect, useMemo, useRef } from "react";

export interface SearchOptions<T> extends Fuse.IFuseOptions<T> {
  maxCount?: number;
}

export default function useSearch<T>(
  term: string | Fuse.Expression | undefined,
  data: T[],
  options: Partial<SearchOptions<T>> = {}
) {
  // eslint-disable-next-line @typescript-eslint/ban-types
  const fuse = useRef<Fuse<T> | null>(null);
  useEffect(() => {
    if (data.length > 0) {
      fuse.current = new Fuse(data, options);
    }
  }, [data, options, fuse]);

  const fullResult = useMemo(
    () => (term ? fuse.current?.search(term).map((i) => i.item) ?? [] : data),
    [fuse, data, term]
  );

  const result = useMemo(
    () =>
      options.maxCount ? fullResult.slice(0, options.maxCount) : fullResult,
    [fullResult, options.maxCount]
  );

  return { fullResult, result };
}
