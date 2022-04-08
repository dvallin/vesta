import { IonContent, IonHeader, IonPage, IonSpinner } from "@ionic/react";
import React, { Suspense } from "react";
import { ToolbarProvider } from "../../hooks/use-toolbar";

export interface PageProps {
  toolbar: React.ReactNode;
  defaultTitle?: string;
}

const Page: React.FC<PageProps> = ({ children, toolbar, defaultTitle }) => (
  <ToolbarProvider defaultTitle={defaultTitle}>
    <IonPage>
      <IonHeader>{toolbar}</IonHeader>
      <IonContent fullscreen>
        <Suspense fallback={<IonSpinner />}>{children}</Suspense>
      </IonContent>
    </IonPage>
  </ToolbarProvider>
);

export default Page;
