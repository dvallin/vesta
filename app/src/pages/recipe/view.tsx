import { IonIcon } from "@ionic/react";
import { createOutline } from "ionicons/icons";
import { useParams } from "react-router";
import RecipeDetails from "../../components/recipe/details";
import Page from "../templates/page";
import ToolbarNavigateButton from "../templates/toolbar/navigate-button";
import Toolbar from "../templates/toolbar/toolbar";

const RecipeViewPage: React.FC = () => {
  const { recipeId } = useParams<{ recipeId?: string }>();
  return (
    <Page
      defaultTitle="Recipe View"
      toolbar={
        <Toolbar>
          <ToolbarNavigateButton to={`/recipe/${recipeId ?? ""}/edit`}>
            <IonIcon icon={createOutline} />
          </ToolbarNavigateButton>
        </Toolbar>
      }
    >
      {recipeId && <RecipeDetails recipeId={recipeId} />}
    </Page>
  );
};

export default RecipeViewPage;
