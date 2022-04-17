import { useIonRouter } from "@ionic/react";
import FormPage from "../templates/form-page";
import ShoppingListForm from "../../components/shopping-list/form";
import Toolbar from "../templates/toolbar/toolbar";
import { useShoppingList } from "../../storage/use-shopping-list";
import useAddMealPlanForm from "../../hooks/use-add-meal-plan-form";
import SubmitButton from "../templates/toolbar/submit-button";

const AddMealPlan: React.FC = () => {
  const shoppingList = useShoppingList();

  const methods = useAddMealPlanForm();

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
        for (const ingredient of updated.shoppingIngredients) {
          const current = shoppingList.shoppingIngredients?.find(
            (i) => i.ingredientName === ingredient.ingredientName
          );
          if (current) {
            current.amount = (current.amount || 0) + (ingredient.amount || 0);
            for (const plan of ingredient.fromPlans) {
              const hasPlan = current.fromPlans.find(
                (p) => p.date === plan.date && p.recipeId === plan.recipeId
              );
              if (!hasPlan) {
                current.fromPlans.push(plan);
              }
            }
          } else {
            shoppingList.shoppingIngredients?.push(ingredient);
          }
        }
        router.push("/shopping-list");
      }}
    >
      <ShoppingListForm />
    </FormPage>
  );
};

export default AddMealPlan;
