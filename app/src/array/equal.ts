import { uniqueArray } from "./unique";

export function equalArray<T, K>(
  left: T[],
  right: T[],
  key: (v: T) => K
): boolean {
  if (left.length !== right.length) {
    return false;
  }
  return uniqueArray([...left, ...right], key).length === left.length;
}
