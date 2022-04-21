import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";

export function toJson<T>(v: Partial<T>): Partial<T> {
  const value = getYjsValue(v) as AbstractType<Partial<T>> | undefined;
  return value?.toJSON() as Partial<T>;
}
