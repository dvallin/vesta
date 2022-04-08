import {
  IonButton,
  IonCol,
  IonContent,
  IonGrid,
  IonInput,
  IonItem,
  IonModal,
  IonRow,
} from "@ionic/react";
import useAddUser from "./use-add-user";
import { QrReader } from "react-qr-reader";
import { useState } from "react";

const AddUser = () => {
  const { connect, foreignId, setForeignId } = useAddUser();
  const [showQrScanner, setShowQrScanner] = useState(false);

  return (
    <IonItem>
      <IonInput
        value={foreignId}
        placeholder="User ID of another user"
        onIonChange={(e) => setForeignId(e.detail.value ?? "")}
      />
      <IonButton onClick={() => setShowQrScanner(true)}>
        Scan Connect QR Code
      </IonButton>
      <IonButton onClick={() => void connect(foreignId)}>
        connect to user
      </IonButton>

      <IonModal
        isOpen={showQrScanner}
        onDidDismiss={() => setShowQrScanner(false)}
      >
        <IonContent>
          <IonGrid>
            <IonRow class="ion-justify-content-center">
              <IonCol>
                <h2>Scan Connect QR Code of a friend</h2>
              </IonCol>
            </IonRow>
            <IonRow class="ion-justify-content-center">
              <IonCol size="12">
                <QrReader
                  constraints={{}}
                  onResult={(result) => {
                    if (result) {
                      setForeignId(result.getText());
                      setShowQrScanner(false);
                    }
                  }}
                />
              </IonCol>
            </IonRow>
          </IonGrid>
        </IonContent>
      </IonModal>
    </IonItem>
  );
};

export default AddUser;
