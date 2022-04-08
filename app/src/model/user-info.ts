import { z } from "zod";

export const userInfoSchema = z.object({
  name: z.string(),
});

export type UserInfo = typeof userInfoSchema._type;
