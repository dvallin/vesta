export function uniqueArray<T, K>(array: T[], key: (v: T) => K): T[] {
  const seen: Set<K> = new Set();
  return array.filter((v) => {
    const k = key(v);
    if (seen.has(k)) {
      return false;
    }

    seen.add(k);
    return true;
  });
}

export function uniqueStringArray(array: string[]): string[] {
  return uniqueArray(array, (i) => i);
}
