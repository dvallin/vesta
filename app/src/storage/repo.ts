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

export async function add<T>(
  type: string,
  value: T,
  id = v4()
): Promise<string> {
  await _storage.set(id, value);
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

export async function getSingleton<T>(
  type: string,
  defaultValue: T
): Promise<Entity<T>> {
  return getByIdOrDefault(type, type, defaultValue);
}

export async function getByIdOrDefault<T>(
  id: string,
  type: string,
  defaultValue: T
): Promise<Entity<T>> {
  const value = await getById<T>(id);

  if (value !== undefined) {
    return value;
  }

  await add(type, defaultValue, id);
  return {
    ...defaultValue,
    id,
  };
}

export async function getById<T>(id: string): Promise<Entity<T> | undefined> {
  const value = (await _storage.get(id)) as T;
  if (value === null) {
    return undefined;
  }
  return {
    ...value,
    id,
  };
}

export async function update<T>(value: Entity<T>): Promise<void> {
  const { id, ...rest } = value;
  await _storage.set(id, rest);
}
