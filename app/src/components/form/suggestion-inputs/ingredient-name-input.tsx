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
        // FIXME: leaky abstraction in syncedstore - missing flatMap
        // eslint-disable-next-line unicorn/prefer-array-flat-map
        data?.map((r) => r.ingredients.map((i) => i.ingredientName)).flat() ??
          []
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
