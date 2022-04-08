import {
  IonAccordion,
  IonAccordionGroup,
  IonItem,
  IonLabel,
  IonList,
} from "@ionic/react";
import AddUser from "../../components/settings/connectivity/add-user";
import MyUser from "../../components/settings/user-info/my-user";
import ShowConnectQr from "../../components/settings/connectivity/show-connect-qr";
import UserList from "../../components/settings/connectivity/user-list";
import TitledPage from "../templates/titled-page";

const SettingsViewPage: React.FC = () => {
  return (
    <TitledPage title="Settings">
      <IonAccordionGroup value="user-info">
        <IonAccordion value="user-info">
          <IonItem slot="header">
            <IonLabel>User Info</IonLabel>
          </IonItem>
          <IonList slot="content">
            <MyUser />
          </IonList>
        </IonAccordion>
        <IonAccordion value="connectivity">
          <IonItem slot="header">
            <IonLabel>Connectivity</IonLabel>
          </IonItem>
          <IonList slot="content">
            <ShowConnectQr />
            <AddUser />
            <UserList />
          </IonList>
        </IonAccordion>
      </IonAccordionGroup>
    </TitledPage>
  );
};

export default SettingsViewPage;
