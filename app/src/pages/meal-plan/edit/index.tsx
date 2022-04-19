import { IonIcon } from "@ionic/react";
import { addOutline } from "ionicons/icons";
import FormPage from "../../templates/form-page";
import MealPlanForm from "../../../components/meal-plan/form";
import Toolbar from "../../templates/toolbar";
import ToolbarEventButton from "../../templates/toolbar/event-button";
import SubmitButton from "../../templates/toolbar/submit-button";
import useEdit from "./use-edit";

const Edit: React.FC = () => {
  const { methods, onSubmit } = useEdit();
  return (
    <FormPage
      defaultTitle="Edit Meal Plan"
      toolbar={
        <Toolbar>
          <ToolbarEventButton eventKey="add">
            <IonIcon icon={addOutline} />
          </ToolbarEventButton>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={onSubmit}
    >
      <MealPlanForm />
    </FormPage>
  );
};

export default Edit;
