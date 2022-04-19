import { IonIcon } from "@ionic/react";
import { createOutline, trashBinOutline } from "ionicons/icons";
import ShoppingListDetails from "../../../components/shopping-list/details";
import Page from "../../templates/page";
import ToolbarEventButton from "../../templates/toolbar/event-button";
import ToolbarNavigateButton from "../../templates/toolbar/navigate-button";
import Toolbar from "../../templates/toolbar";

const ShoppingListViewPage: React.FC = () => {
  return (
    <Page
      defaultTitle="Shopping List"
      toolbar={
        <Toolbar>
          <ToolbarEventButton eventKey="clean">
            <IonIcon icon={trashBinOutline} />
          </ToolbarEventButton>
          <ToolbarNavigateButton to="/shopping-list/edit">
            <IonIcon icon={createOutline} />
          </ToolbarNavigateButton>
        </Toolbar>
      }
    >
      <ShoppingListDetails />
    </Page>
  );
};

export default ShoppingListViewPage;
