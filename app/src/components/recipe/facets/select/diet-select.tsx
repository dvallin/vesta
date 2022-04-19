import { RecipeFacet } from "../../../../model/recipe";
import FacetSelect from "./facet-select";

export interface CountrySelectProps {
  currentFacets: RecipeFacet[];
  onChange: (values: RecipeFacet[]) => void;
}

const DietSelect = ({ currentFacets, onChange }: CountrySelectProps) => {
  return (
    <FacetSelect
      multiple
      facetKey="diet"
      placeholder="Diet"
      value={currentFacets}
      onChange={onChange}
      facets={[
        { value: "blw", icon: "👶" },
        { value: "gluten-free", icon: "🌾" },
        { value: "keto", icon: "💪" },
        { value: "paleo", icon: "🗿" },
        { value: "vegan", icon: "🌿" },
        { value: "vegetarian", icon: "🌱" },
      ]}
    />
  );
};

export default DietSelect;
