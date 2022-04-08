import { IonInput, IonItem, IonLabel } from "@ionic/react";
import { useUserInfo } from "../../../storage/use-user-info";

const MyUser = () => {
  const { data: user, update } = useUserInfo();

  if (!user) {
    return <></>;
  }

  return (
    <IonItem>
      <IonLabel>Username</IonLabel>
      <IonInput
        value={user.name}
        onIonChange={(e) => update({ name: e.detail.value ?? "", id: user.id })}
      />
    </IonItem>
  );
};

export default MyUser;
