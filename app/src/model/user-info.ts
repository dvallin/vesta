import { z } from "zod";

export const userInfoSchema = z.object({
  id: z.string(),
  name: z.string(),
});

export type UserInfo = typeof userInfoSchema._type;
