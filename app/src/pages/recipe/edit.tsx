import { useIonRouter } from "@ionic/react";
import { useParams } from "react-router";
import { useRecipes } from "../../storage/use-recipes";
import useRecipeForm from "../../hooks/use-recipe-form";
import FormPage from "../templates/form-page";
import RecipeForm from "../../components/recipe/form";
import Toolbar from "../templates/toolbar/toolbar";
import SubmitButton from "../templates/toolbar/submit-button";
import RecipeDeleteButton from "../../components/recipe/delete-button";

const Edit: React.FC = () => {
  const { recipeId } = useParams<{ recipeId?: string }>();
  const methods = useRecipeForm(recipeId);

  const { update } = useRecipes();
  const router = useIonRouter();
  return (
    <FormPage
      defaultTitle="Edit Recipe"
      toolbar={
        <Toolbar>
          <RecipeDeleteButton />
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={(updated) => {
        console.log(updated);
        if (recipeId) {
          void update({ ...updated, id: recipeId });
          router.goBack();
        }
      }}
    >
      <RecipeForm />
    </FormPage>
  );
};

export default Edit;
