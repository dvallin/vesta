import { useEffect, useState } from "react";
import QRCode from "react-qr-code";
import { IonIcon, IonItem, IonList } from "@ionic/react";
import { cloud } from "ionicons/icons";
import useNetwork, {
  ConnectHandler,
  DataHandler,
} from "../../connectivity/use-network";
import { useUserInfo } from "../../storage/use-user-info";

type UserInfoData = { type: "user-info"; name: string | undefined };

function useUserList() {
  const [foreignId, setForeignId] = useState("");
  const { data: user, update } = useUserInfo();
  const network = useNetwork();

  useEffect(() => {
    const onData: DataHandler<UserInfoData> = {
      applies: (id, data): data is UserInfoData =>
        "type" in data && data.type === "user-info",
      apply: (id, data, { setPeerUsername }) => {
        setPeerUsername(id, data.name);
      },
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
    peers: network.peers,
    connect: (id: string) => network.connect(id),
    user,
    update,
    foreignId,
    setForeignId,
  };
}

const UserList = () => {
  const { peers, connect, user, update, foreignId, setForeignId } =
    useUserList();

  return (
    <>
      {user && (
        <>
          <h2>your id {user.id}</h2>
          <QRCode value={user.id} />
          <input
            type={"text"}
            value={user.name}
            onChange={(e) => update({ ...user, name: e.target.value })}
          />
        </>
      )}
      <input
        type={"text"}
        value={foreignId}
        onChange={(e) => setForeignId(e.target.value)}
      />
      <button onClick={() => connect(foreignId)}>add</button>
      <IonList>
        {peers.map(({ id, online, username }) => (
          <IonItem key={id}>
            {username ?? id}:{" "}
            <IonIcon color={online ? "success" : "danger"} icon={cloud} />
          </IonItem>
        ))}
      </IonList>
    </>
  );
};

export default UserList;
