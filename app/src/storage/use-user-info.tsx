import { v4 } from "uuid";
import useNetwork from "../connectivity/use-network";
import { UserInfo } from "../model/user-info";
import { getById, update } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

const defaultValue: UserInfo = {
  id: v4(),
  name: "",
};

export type UserInfoData = { type: "user-info"; name: string | undefined };

export function useUserInfo() {
  const network = useNetwork();
  return useSwrRepository(
    "user-info",
    async () => getById("user-info", { type: "user-info", defaultValue }),
    {
      update: async (info: UserInfo) => {
        // broadcast this change directly to all peers
        network.broadcast<UserInfoData>({ type: "user-info", name: info.name });
        // serialize into local-storage
        return update("user-info", info);
      },
    }
  );
}
