import { IonIcon, useIonRouter } from "@ionic/react";
import { addOutline } from "ionicons/icons";
import FormPage from "../templates/form-page";
import ShoppingListForm from "../../components/shopping-list/form";
import Toolbar from "../templates/toolbar/toolbar";
import ToolbarEventButton from "../templates/toolbar/event-button";
import { useShoppingList } from "../../storage/use-shopping-list";
import useShoppingListForm from "../../hooks/use-shopping-list-form";
import SubmitButton from "../templates/toolbar/submit-button";

const Edit: React.FC = () => {
  const { data: list, update, add } = useShoppingList();
  const methods = useShoppingListForm(list);

  const router = useIonRouter();
  return (
    <FormPage
      defaultTitle="Edit Shopping List"
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
        if (list) {
          void update({ ...updated, id: list.id });
        } else {
          void add(updated);
        }

        router.goBack();
      }}
    >
      <ShoppingListForm />
    </FormPage>
  );
};

export default Edit;
