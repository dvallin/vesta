import { IonButton } from "@ionic/react";
import { useToolbar } from "../../../hooks/use-toolbar";

export interface ToolbarEventButtonProps
  extends React.ComponentPropsWithRef<typeof IonButton> {
  eventKey: string;
}

const ToolbarEventButton: React.FC<ToolbarEventButtonProps> = ({
  eventKey,
  children,
  ...buttonProps
}) => {
  const { dispatch } = useToolbar();
  return (
    <IonButton
      onClick={() => {
        dispatch(eventKey);
      }}
      {...buttonProps}
    >
      {children}
    </IonButton>
  );
};

export default ToolbarEventButton;
