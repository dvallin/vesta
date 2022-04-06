import { IonModal } from "@ionic/react";
import { useState } from "react";
import { Controller } from "react-hook-form";
import RecipeItem from "./label";
import RecipeSearch from "./search";

export interface RecipeSelectProps {
  name: string;
}

const RecipeSelect: React.FC<RecipeSelectProps> = ({ name }) => {
  const [edit, setEdit] = useState(false);
  return (
    <Controller
      key={name}
      name={name}
      render={({ field: { onChange, value } }) => (
        <>
          <IonModal
            isOpen={edit}
            onDidDismiss={() => setEdit(false)}
            breakpoints={[0.2, 0.5, 1]}
            initialBreakpoint={0.5}
          >
            <RecipeSearch
              maxCount={10}
              onSelect={(recipe) => {
                setEdit(false);
                onChange(recipe.id);
              }}
            />
          </IonModal>
          <RecipeItem
            recipeId={value as string}
            defaultLabel="no recipe selected..."
            onClick={() => {
              setEdit(true);
            }}
          />
        </>
      )}
    />
  );
};

export default RecipeSelect;
