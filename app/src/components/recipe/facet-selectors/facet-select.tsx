import { IonSelect, IonSelectOption } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";
import { equalArray } from "../../../array/equal";
import { partition } from "../../../array/partition";
import { Recipe, RecipeFacet } from "../../../model/recipe";

type IonSelectProps = React.ComponentProps<typeof IonSelect>;
export interface FacetSelectProps extends IonSelectProps {
  facetKey: string;
  facets: Omit<RecipeFacet, "key">[];
}

const FacetSelect: React.FC<FacetSelectProps> = ({
  facetKey,
  facets,
  ...ionSelectProps
}) => {
  const { control } = useFormContext<Recipe>();
  return (
    <Controller
      control={control}
      name="facets"
      render={({ field }) => {
        const [currentFacets, otherFacets] = partition(
          field.value || [],
          (f) => f.key === facetKey
        );
        return (
          <>
            <IonSelect
              value={
                ionSelectProps.multiple
                  ? currentFacets.map((f) => f.value)
                  : currentFacets[0]?.value
              }
              onIonChange={({ detail }) => {
                const selection: string[] =
                  typeof detail.value === "string"
                    ? detail.value.split(",")
                    : (detail.value as string[]);
                const selectedFacets: RecipeFacet[] = facets
                  .filter((f) => selection.includes(f.value))
                  .map((f) => ({ ...f, key: facetKey }));
                if (
                  !equalArray(currentFacets, selectedFacets, (f) => f.value)
                ) {
                  field.onChange([...otherFacets, ...selectedFacets]);
                }
              }}
              {...ionSelectProps}
            >
              <IonSelectOption value={""}>None</IonSelectOption>
              {facets.map(({ value, icon }) => (
                <IonSelectOption key={value} value={value}>
                  {value} {icon}
                </IonSelectOption>
              ))}
            </IonSelect>
          </>
        );
      }}
    />
  );
};

export default FacetSelect;
