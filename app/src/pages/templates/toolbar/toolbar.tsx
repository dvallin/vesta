import { IonBackButton, IonButtons, IonTitle, IonToolbar } from "@ionic/react";
import React from "react";
import { useToolbar } from "../../../hooks/use-toolbar";

const Toolbar: React.FC = ({ children }) => {
  const { title } = useToolbar();
  return (
    <IonToolbar>
      <IonButtons>
        <IonBackButton />
        <IonTitle>{title}</IonTitle>
        {children}
      </IonButtons>
    </IonToolbar>
  );
};

export default Toolbar;
