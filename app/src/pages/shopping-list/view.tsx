import { IonIcon } from "@ionic/react";
import { createOutline, trashBinOutline } from "ionicons/icons";
import ShoppingListDetails from "../../components/shopping-list/details";
import useShoppingListForm from "../../hooks/use-shopping-list-form";
import { useShoppingList } from "../../storage/use-shopping-list";
import SynchFormPage from "../templates/synch-form-page";
import ToolbarEventButton from "../templates/toolbar/event-button";
import ToolbarNavigateButton from "../templates/toolbar/navigate-button";
import Toolbar from "../templates/toolbar/toolbar";

const ShoppingListViewPage: React.FC = () => {
  const { data: list, update, add } = useShoppingList();
  const methods = useShoppingListForm(list);
  return (
    <SynchFormPage
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
      methods={methods}
      onSubmit={(updated) => {
        if (list) {
          void update({ ...updated, id: list.id });
        } else {
          void add(updated);
        }
      }}
    >
      <ShoppingListDetails />
    </SynchFormPage>
  );
};

export default ShoppingListViewPage;
