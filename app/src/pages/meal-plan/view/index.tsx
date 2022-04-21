import { IonIcon } from "@ionic/react";
import { cartOutline, createOutline } from "ionicons/icons";
import MealPlanDetails from "../../../components/meal-plan/details";
import MealPlanItemPreview from "../../../components/meal-plan/item/preview";
import { MealPlanItemPreviewContext } from "../../../components/meal-plan/use-meal-plan-item-preview";
import Page from "../../templates/page";
import ToolbarNavigateButton from "../../templates/toolbar/navigate-button";
import Toolbar from "../../templates/toolbar";

const MealPlanView: React.FC = () => (
  <Page
    defaultTitle="Meal Plan"
    toolbar={
      <Toolbar>
        <ToolbarNavigateButton to="/shopping-list/add-meal-plan">
          <IonIcon icon={cartOutline} />
        </ToolbarNavigateButton>
        <ToolbarNavigateButton to="/meal-plan/edit">
          <IonIcon icon={createOutline} />
        </ToolbarNavigateButton>
      </Toolbar>
    }
  >
    <MealPlanItemPreviewContext>
      <MealPlanItemPreview />
      <MealPlanDetails />
    </MealPlanItemPreviewContext>
  </Page>
);

export default MealPlanView;
