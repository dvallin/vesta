import { IonSelect } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";
import { Recipe, RecipeFacet } from "../../../../model/recipe";
import FacetSelect from "../select/facet-select";

type IonSelectProps = React.ComponentProps<typeof IonSelect>;
export interface FacetEditProps extends Omit<IonSelectProps, "onChange"> {
  facetKey: string;
  facets: Omit<RecipeFacet, "key">[];
}

const FacetEdit: React.FC<FacetEditProps> = ({
  facetKey,
  facets,
  ...ionSelectProps
}) => {
  const { control } = useFormContext<Recipe>();
  return (
    <Controller
      control={control}
      name="facets"
      render={({ field }) => (
        <FacetSelect
          facetKey={facetKey}
          facets={facets}
          value={field.value || []}
          onChange={(selection) => {
            field.onChange(selection);
          }}
          {...ionSelectProps}
        />
      )}
    />
  );
};

export default FacetEdit;
