import { IonButton, IonIcon, useIonAlert, useIonRouter } from "@ionic/react";
import { useParams } from "react-router";
import { useRecipe, useRecipes } from "../../storage/use-recipes";
import { trashBinOutline } from "ionicons/icons";

const RecipeDeleteButton: React.FC = () => {
  const { recipeId } = useParams<{ recipeId?: string }>();

  const [present] = useIonAlert();
  const { remove } = useRecipes();
  const recipe = useRecipe(recipeId);
  const router = useIonRouter();
  return (
    <IonButton
      color="danger"
      onClick={() => {
        if (recipeId) {
          void present({
            header: `Delete ${recipe?.name || ""}?`,
            message: "You are about to permanently delete a recipe!",
            buttons: [
              "Cancel",
              {
                text: "Delete",
                handler: () => {
                  remove(recipeId);
                  router.push("/recipe/search");
                },
              },
            ],
          });
        }
      }}
    >
      <IonIcon icon={trashBinOutline} />
    </IonButton>
  );
};

export default RecipeDeleteButton;
