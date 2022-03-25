import { IonSearchbar } from "@ionic/react";
import { useState } from "react";
import useRecipeSearch from "../../hooks/use-recipe-search";
import { Recipe } from "../../model/recipe";
import { Entity } from "../../model/entity";
import RecipeList from "./list";

export interface RecipeSearchProps {
  maxCount?: number;
  onSelect: (recipe: Entity<Recipe>) => void;
}

const RecipeSearch: React.FC<RecipeSearchProps> = ({ onSelect, maxCount }) => {
  const [term, setTerm] = useState("");
  const recipes = useRecipeSearch(term, maxCount);
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
      <RecipeList recipes={recipes} onClick={onSelect} />
    </>
  );
};

export default RecipeSearch;
