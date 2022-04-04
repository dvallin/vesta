import Peer from "peerjs";
import { useMemo } from "react";
import { useUserInfo } from "../storage/use-user-info";

export default function usePeerClient() {
  const { data: user } = useUserInfo();
  const id = user?.id;
  return useMemo(
    () =>
      id ? new Peer(id, { host: "peerjs.92k.de", secure: true }) : undefined,
    [id]
  );
}
