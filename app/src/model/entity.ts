import { z } from "zod";

export type Entity<T> = T & { id: string };

export const entitySchema = z.object({ id: z.string() });
