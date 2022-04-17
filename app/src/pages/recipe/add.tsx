import { useIonRouter } from "@ionic/react";
import { useRecipes } from "../../storage/use-recipes";
import FormPage from "../templates/form-page";
import useRecipeForm from "../../hooks/use-recipe-form";
import RecipeForm from "../../components/recipe/form";
import Toolbar from "../templates/toolbar/toolbar";
import SubmitButton from "../templates/toolbar/submit-button";

const Add: React.FC = () => {
  const { add } = useRecipes();
  const router = useIonRouter();
  const methods = useRecipeForm();
  return (
    <FormPage
      defaultTitle="Add Recipe"
      toolbar={
        <Toolbar>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={(recipe) => {
        const id = add(recipe);
        router.push(`/recipe/${id}`);
      }}
    >
      <RecipeForm />
    </FormPage>
  );
};

export default Add;
