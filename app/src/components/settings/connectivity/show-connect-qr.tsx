import {
  IonButton,
  IonContent,
  IonGrid,
  IonItem,
  IonLabel,
  IonModal,
  IonRow,
} from "@ionic/react";
import QRCode from "react-qr-code";
import { useUserInfo } from "../../../storage/use-user-info";

const ShowConnectQr = () => {
  const { data: user } = useUserInfo();

  if (!user) {
    return <></>;
  }

  return (
    <IonItem>
      <IonLabel>My user id {user.id}</IonLabel>
      <IonButton id="show-connect-qr-code">Show Connect QR Code</IonButton>
      <IonModal trigger="show-connect-qr-code">
        <IonContent>
          <IonGrid>
            <IonRow class="ion-justify-content-center">
              <h2>{user.id}</h2>
            </IonRow>
            <IonRow class="ion-justify-content-center">
              <QRCode value={user.id} />
            </IonRow>
            <IonRow class="ion-justify-content-center">
              Have a friend scan this code connect with him.
            </IonRow>
          </IonGrid>
        </IonContent>
      </IonModal>
    </IonItem>
  );
};

export default ShowConnectQr;
