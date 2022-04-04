import { IonTitle, IonToolbar } from "@ionic/react";
import useToolbar from "../../hooks/use-toolbar";
import Page from "./page";

export interface DefaultPageProps {
  title: string;
}

const Toolbar: React.FC = () => {
  const { title } = useToolbar();
  return (
    <IonToolbar>
      <IonTitle>{title}</IonTitle>
    </IonToolbar>
  );
};

const TitledPage: React.FC<DefaultPageProps> = ({ children, title }) => (
  <Page toolbar={<Toolbar />} defaultTitle={title}>
    {children}
  </Page>
);

export default TitledPage;
