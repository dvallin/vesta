import { Key, unstable_serialize } from "swr";

export type SwrCache = Map<string, unknown>;
export type SwrProvider = () => SwrCache;

export function createCache(...entries: [Key, unknown][]): SwrCache {
  const cache = new Map<string, unknown>();
  entries.forEach(([key, value]) => {
    cache.set(unstable_serialize(key), value);
  });
  return cache;
}

export function merge(...providers: SwrProvider[]): SwrProvider {
  return () => {
    const cache = new Map<string, unknown>();
    for (const provider of providers) {
      const current = provider();
      current.forEach((value, key) => {
        cache.set(key, value);
      });
    }
    return cache;
  };
}
