import { useIonRouter } from "@ionic/react";
import RecipeSearch from "../../components/recipe/search";
import TitledPage from "../templates/titled-page";

const RecipeSearchPage: React.FC = () => {
  const router = useIonRouter();
  return (
    <TitledPage title="Recipe Search">
      <RecipeSearch
        onSelect={(recipe) => {
          router.push(`/recipe/${recipe.id}`);
        }}
      />
    </TitledPage>
  );
};

export default RecipeSearchPage;
