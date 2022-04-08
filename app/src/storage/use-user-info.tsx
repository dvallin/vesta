import useNetwork from "../connectivity/use-network";
import { Entity } from "../model/entity";
import { UserInfo } from "../model/user-info";
import { getSingleton, update } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

const defaultValue: UserInfo = {
  name: "",
};

export type UserInfoData = { type: "user-info"; name: string | undefined };

export function useUserInfo() {
  const network = useNetwork();
  return useSwrRepository(
    "user-info",
    async () => getSingleton("user-info", defaultValue),
    {
      update: async (info: Entity<UserInfo>) => {
        // broadcast this change directly to all peers
        network.broadcast<UserInfoData>({ type: "user-info", name: info.name });
        // serialize into local-storage
        return update(info);
      },
    }
  );
}
