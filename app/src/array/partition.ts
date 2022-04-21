export function partition<T>(
  array: T[],
  predicate: (v: T) => boolean
): [T[], T[]] {
  const result: [T[], T[]] = [[], []];
  for (const value of array) {
    result[predicate(value) ? 0 : 1].push(value);
  }
  return result;
}
