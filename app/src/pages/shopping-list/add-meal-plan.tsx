import { useIonRouter } from "@ionic/react";
import FormPage from "../templates/form-page";
import ShoppingListForm from "../../components/shopping-list/form";
import Toolbar from "../templates/toolbar/toolbar";
import useShoppingListForm from "../../hooks/use-shopping-list-form";
import { useShoppingList } from "../../storage/use-shopping-list";
import useShoppingListFromMealPlan from "../../hooks/use-shopping-list-from-meal-plan";
import { combine } from "../../model/shopping-list";
import SubmitButton from "../templates/toolbar/submit-button";

const AddMealPlan: React.FC = () => {
  const { data: list, update, add } = useShoppingList();
  const shoppingListFromMealPlan = useShoppingListFromMealPlan();

  const methods = useShoppingListForm(shoppingListFromMealPlan);

  const router = useIonRouter();
  return (
    <FormPage
      defaultTitle="Add Meal Plan to Shopping List"
      toolbar={
        <Toolbar>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={(updated) => {
        if (list) {
          const combined = combine(list, updated);
          void update({ ...combined, id: list.id });
        } else {
          void add(updated);
        }

        router.push("/shopping-list");
      }}
    >
      <ShoppingListForm />
    </FormPage>
  );
};

export default AddMealPlan;
