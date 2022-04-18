import { IonItem, IonLabel, IonList, IonNote } from "@ionic/react";
import { Entity } from "../../model/entity";
import { Recipe } from "../../model/recipe";

export interface RecipeListProps {
  recipes: Array<Entity<Recipe>>;
  onClick?: (recipe: Entity<Recipe>) => void;
}

const RecipeList: React.FC<RecipeListProps> = ({ recipes, onClick }) => (
  <IonList>
    {recipes.map((recipe) => (
      <IonItem
        key={recipe.id}
        button
        onClick={() => {
          if (onClick) {
            onClick(recipe);
          }
        }}
      >
        <IonLabel className="ion-text-wrap">{recipe.name}</IonLabel>
        <IonNote slot="end">
          {recipe?.facets?.map(({ value, icon }) => icon ?? value).join(" ")}
        </IonNote>
      </IonItem>
    ))}
  </IonList>
);

export default RecipeList;
