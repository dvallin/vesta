import { IonIcon, IonItem, IonLabel, IonListHeader } from "@ionic/react";
import { cloud } from "ionicons/icons";
import useNetwork from "../../../connectivity/use-network";

const UserList = () => {
  const { peers } = useNetwork();

  return (
    <>
      <IonListHeader>Connected users</IonListHeader>
      {peers.length > 0 ? (
        peers.map(({ id, online, username }) => (
          <IonItem key={id}>
            {username ?? id}:{" "}
            <IonIcon color={online ? "success" : "danger"} icon={cloud} />
          </IonItem>
        ))
      ) : (
        <IonItem>
          <IonLabel>You are not connected to another user</IonLabel>
        </IonItem>
      )}
    </>
  );
};

export default UserList;
