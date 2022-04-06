import { UserInfo } from "../../src/model/user-info";
import { createCache, SwrCache } from "./swr-cache";

const standardUserInfo: UserInfo = {
  id: "da29a56e-e9df-42f2-961c-d313f6d1b2aa",
  name: "my username 43",
};

export const userInfo: () => SwrCache = () =>
  createCache(["user-info", standardUserInfo]);
