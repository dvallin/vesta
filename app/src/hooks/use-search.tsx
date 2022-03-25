import Fuse from "fuse.js";
import { useEffect, useMemo, useRef } from "react";

export interface SearchOptions<T> extends Fuse.IFuseOptions<T> {
  maxCount?: number;
}

export default function useSearch<T>(
  term: string,
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

  return useMemo(() => {
    const result =
      term.length > 0
        ? fuse.current?.search(term).map((i) => i.item) ?? []
        : data;
    return options.maxCount ? result.slice(0, options.maxCount) : result;
  }, [fuse, data, term, options.maxCount]);
}
