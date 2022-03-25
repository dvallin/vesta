import { IonButton, useIonRouter } from "@ionic/react";

export interface ToolbarNavigateButtonProps {
  to: string;
}

const ToolbarNavigateButton: React.FC<ToolbarNavigateButtonProps> = ({
  to,
  children,
}) => {
  const router = useIonRouter();
  return (
    <IonButton
      onClick={() => {
        router.push(to);
      }}
    >
      {children}
    </IonButton>
  );
};

export default ToolbarNavigateButton;
