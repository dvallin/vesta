import { useIonRouter } from "@ionic/react";
import { useParams } from "react-router";
import { useRecipe, useRecipes } from "../../storage/use-recipes";
import useRecipeForm from "../../hooks/use-recipe-form";
import FormPage from "../templates/form-page";
import RecipeForm from "../../components/recipe/form";
import Toolbar from "../templates/toolbar/toolbar";
import SubmitButton from "../templates/toolbar/submit-button";

const Edit: React.FC = () => {
  const { recipeId } = useParams<{ recipeId?: string }>();
  const recipe = useRecipe(recipeId);
  const methods = useRecipeForm(recipe);

  const { update } = useRecipes();
  const router = useIonRouter();
  return (
    <FormPage
      defaultTitle="Edit Recipe"
      toolbar={
        <Toolbar>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={(recipe) => {
        if (recipeId) {
          void update(recipeId, recipe);
          router.goBack();
        }
      }}
    >
      <RecipeForm />
    </FormPage>
  );
};

export default Edit;
