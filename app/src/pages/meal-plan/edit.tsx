import { IonIcon, useIonRouter } from "@ionic/react";
import { addOutline } from "ionicons/icons";
import FormPage from "../templates/form-page";
import { useMealPlan } from "../../storage/use-meal-plan";
import useMealPlanForm from "../../hooks/use-meal-plan-form";
import MealPlanForm from "../../components/meal-plan/form";
import Toolbar from "../templates/toolbar/toolbar";
import ToolbarEventButton from "../templates/toolbar/event-button";
import SubmitButton from "../templates/toolbar/submit-button";

const Edit: React.FC = () => {
  const { data: plan, update, add } = useMealPlan();
  const methods = useMealPlanForm(plan);

  const router = useIonRouter();
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
      onSubmit={(updated) => {
        if (plan) {
          void update(plan?.id, updated);
        } else {
          void add(updated);
        }

        router.goBack();
      }}
    >
      <MealPlanForm />
    </FormPage>
  );
};

export default Edit;
