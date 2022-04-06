import { useEffect, useState } from "react";
import useNetwork, {
  ConnectHandler,
  DataHandler,
} from "../../../connectivity/use-network";
import { UserInfoData, useUserInfo } from "../../../storage/use-user-info";

export default function useAddUser() {
  const [foreignId, setForeignId] = useState("");
  const { data: user } = useUserInfo();
  const network = useNetwork();

  useEffect(() => {
    const onData: DataHandler<UserInfoData> = {
      applies: (id, data): data is UserInfoData =>
        "type" in data && data.type === "user-info",
      apply: (id, data, { setPeerUsername }) => setPeerUsername(id, data.name),
    };

    const onConnect: ConnectHandler = {
      applies: () => true,
      apply: (id, { send }) => {
        send<UserInfoData>(id, { type: "user-info", name: user?.name });
      },
    };

    network.on("data", onData);
    network.on("connect", onConnect);
    return () => {
      network.off("data", onData);
      network.off("connect", onConnect);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user]);

  return {
    connect: (id: string) => network.connect(id),
    foreignId,
    setForeignId,
  };
}
