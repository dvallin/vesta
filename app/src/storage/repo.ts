import { Storage } from "@ionic/storage";
import { v4 } from "uuid";
import { Entity } from "../model/entity";

const _storage = new Storage({ name: "repo" });

_storage.create().finally(() => {
  // default
});

type Index = Record<string, string[]>;
let _index: Index | undefined;

async function getIndex(): Promise<Index> {
  if (_index) {
    return _index;
  }

  const m = await (_storage.get("repo-index") as Promise<Index | undefined>);
  _index = m;
  return m ?? {};
}

export async function add<T>(type: string, value: T): Promise<string> {
  const id = v4();
  await _storage.set(id, { ...value, id });
  const index = await getIndex();
  if (index[type] === undefined) {
    index[type] = [];
  }

  index[type].push(id);
  await _storage.set("repo-index", index);
  return id;
}

export async function* streamAllByType<T>(type: string): AsyncGenerator<T> {
  const index = await getIndex();
  for (const id of index[type] || []) {
    // eslint-disable-next-line no-await-in-loop
    const value = await (_storage.get(id) as Promise<T>);
    yield { id, ...value };
  }
}

export async function getAllByType<T>(type: string): Promise<Array<Entity<T>>> {
  const allItems = [];
  for await (const item of streamAllByType<Entity<T>>(type)) {
    allItems.push(item);
  }

  return allItems;
}

export async function getFirstByType<T>(type: string): Promise<Entity<T>> {
  const next = await streamAllByType(type).next();
  return next.value as Entity<T>;
}

export interface GetByIdOptions<T> {
  defaultValue: T;
  type: string;
}
export async function getById<T>(
  id: string,
  options: Partial<GetByIdOptions<T>> = {}
): Promise<T> {
  const value = (await _storage.get(id)) as Promise<T>;
  if (
    value === null &&
    options.type !== undefined &&
    options.defaultValue !== undefined
  ) {
    await add(options.type, options.defaultValue);
    return options.defaultValue;
  }
  return value;
}

export async function update<T>(id: string, value: T): Promise<void> {
  await _storage.set(id, value);
}
