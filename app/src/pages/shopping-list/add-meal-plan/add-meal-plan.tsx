import FormPage from "../../templates/form-page";
import ShoppingListForm from "../../../components/shopping-list/form";
import Toolbar from "../../templates/toolbar/toolbar";
import useAddMealPlan from "./use-add-meal-plan";
import SubmitButton from "../../templates/toolbar/submit-button";

const AddMealPlan: React.FC = () => {
  const { methods, onSubmit } = useAddMealPlan();

  return (
    <FormPage
      defaultTitle="Add Meal Plan to Shopping List"
      toolbar={
        <Toolbar>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={onSubmit}
    >
      <ShoppingListForm />
    </FormPage>
  );
};

export default AddMealPlan;
