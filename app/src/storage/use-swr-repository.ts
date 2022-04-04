import { useMemo } from "react";
import useSWR, { Key, SWRConfiguration, SWRResponse } from "swr";
import { KeyedMutator } from "swr/dist/types";
import useImmutableSWR from "swr/immutable";

export type SwrRepository<T> = SWRResponse<T, Error>;
export type SwrEntity<T> = Omit<SWRResponse<T, Error>, "mutate">;

/**
 * Creates an SWR repository that never revalidates its data (useful for immutable data like product data, distribution brands etc...)
 */
export function useImmutableSwrRepository<T>(
  key: Key,
  fetcher: () => Promise<T>,
  config?: Partial<SWRConfiguration>
): SwrRepository<T> {
  return useImmutableSWR<T, Error>(key, fetcher, config);
}

/**
 * Creates an SWR repository that revalidates its data on method calls and according to global settings (e.g. mount, focus, reconnect)
 */
export type Method = (...args: never[]) => Promise<unknown> | unknown;
export function useSwrRepository<T, O extends Record<string, Method>>(
  key: Key,
  fetcher: () => Promise<T>,
  methods: O,
  config?: Partial<SWRConfiguration>
): SwrRepository<T> & O {
  const repo = useSWR<T, Error>(key, fetcher, config);

  const wrappedMethods = useMemo(() => {
    const m: Record<string, unknown> = {};
    for (const method of Object.keys(methods)) {
      m[method] = callAndMutate(repo.mutate, methods[method]);
    }
    return m;
  }, [methods, repo.mutate]);

  return {
    ...repo,
    ...(wrappedMethods as O),
  };
}

function callAndMutate<T>(mutate: KeyedMutator<T>, callback: Method): Method {
  return async (...args) => {
    const result = await callback(...args);
    void mutate();
    return result;
  };
}
