import { v4 } from "uuid";
import { UserInfo } from "../model/user-info";
import { getById, update } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

const defaultValue: UserInfo = {
  id: v4(),
  name: "",
};

export function useUserInfo() {
  return useSwrRepository(
    "user-info",
    async () => getById("user-info", { type: "user-info", defaultValue }),
    {
      update: async (info: UserInfo) => update("user-info", info),
    }
  );
}
