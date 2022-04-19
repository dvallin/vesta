import { IonSelect, IonSelectOption } from "@ionic/react";
import { equalArray } from "../../../../array/equal";
import { partition } from "../../../../array/partition";
import { RecipeFacet } from "../../../../model/recipe";

type IonSelectProps = React.ComponentProps<typeof IonSelect>;
export interface FacetSelectProps
  extends Omit<IonSelectProps, "value" | "onChange"> {
  facetKey: string;
  facets: Omit<RecipeFacet, "key">[];
  value: RecipeFacet[];
  onChange: (values: RecipeFacet[]) => void;
}

const FacetSelect: React.FC<FacetSelectProps> = ({
  facetKey,
  facets,
  value,
  onChange,
  ...ionSelectProps
}) => {
  const [currentFacets, otherFacets] = partition(
    value,
    (f) => f.key === facetKey
  );
  return (
    <IonSelect
      value={ionSelectProps.multiple ? value : value[0]}
      onIonChange={({ detail }) => {
        let selection: string[] = [];
        if (detail.value !== "") {
          selection =
            typeof detail.value === "string"
              ? detail.value.split(",")
              : (detail.value as string[]);
        }

        const selectedFacets: RecipeFacet[] = facets
          .filter((f) => selection.includes(f.value))
          .map((f) => ({ ...f, key: facetKey }));
        if (!equalArray(selectedFacets, currentFacets, (i) => i.value)) {
          onChange([...selectedFacets, ...otherFacets]);
        }
      }}
      {...ionSelectProps}
    >
      {ionSelectProps.multiple || (
        <IonSelectOption value={""}>None</IonSelectOption>
      )}
      {facets.map(({ value, icon }) => (
        <IonSelectOption key={value} value={value}>
          {value} {icon}
        </IonSelectOption>
      ))}
    </IonSelect>
  );
};

export default FacetSelect;
