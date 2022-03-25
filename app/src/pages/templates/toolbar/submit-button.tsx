import { IonIcon } from "@ionic/react";
import { checkmarkOutline } from "ionicons/icons";
import { useFormContext } from "react-hook-form";
import ToolbarEventButton from "./event-button";

const SubmitButton: React.FC = () => {
  const { formState } = useFormContext();
  return (
    <ToolbarEventButton
      eventKey="submit"
      color="primary"
      disabled={!formState.isValid}
    >
      <IonIcon icon={checkmarkOutline} />
    </ToolbarEventButton>
  );
};

export default SubmitButton;
