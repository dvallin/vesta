import { IonSearchbar } from "@ionic/react";
import { Recipe } from "../../../model/recipe";
import { Entity } from "../../../model/entity";
import RecipeList from "../list";
import useSearch from "./use-search";

export interface RecipeSearchProps {
  maxCount?: number;
  onSelect: (recipe: Entity<Recipe>) => void;
}

const RecipeSearch: React.FC<RecipeSearchProps> = ({ onSelect, maxCount }) => {
  const { result, term, setTerm } = useSearch(maxCount);
  return (
    <>
      <IonSearchbar
        value={term}
        onIonChange={({ detail: { value } }) => {
          if (value) {
            setTerm(value);
          }
        }}
      />
      <RecipeList recipes={result} onClick={onSelect} />
    </>
  );
};

export default RecipeSearch;
