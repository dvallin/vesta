import { useMemo } from "react";
import { useRecipes } from "../../../storage/use-recipes";
import { uniqueStringArray } from "../../../unique";
import SuggestionInput, { SuggestionInputProps } from "./suggestion-input";

const IngredientNameInput: React.FC<
  Omit<SuggestionInputProps, "label" | "type" | "suggestions">
> = (props) => {
  const { data } = useRecipes();
  const suggestions = useMemo(
    () =>
      uniqueStringArray(
        data?.flatMap((r) => r.ingredients.map((i) => i.ingredientName)) ?? []
      ).sort(),
    [data]
  );
  return (
    <SuggestionInput
      {...props}
      label="Name"
      type="text"
      suggestions={suggestions}
    />
  );
};

export default IngredientNameInput;
