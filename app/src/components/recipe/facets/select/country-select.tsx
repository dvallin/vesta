import { RecipeFacet } from "../../../../model/recipe";
import FacetSelect from "./facet-select";

export interface CountrySelectProps {
  currentFacets: RecipeFacet[];
  onChange: (values: RecipeFacet[]) => void;
}

const CountrySelect = ({ currentFacets, onChange }: CountrySelectProps) => {
  return (
    <FacetSelect
      multiple
      facetKey="country"
      placeholder="Country"
      value={currentFacets}
      onChange={onChange}
      facets={[
        { value: "Chinese", icon: "🇨🇳" },
        { value: "French", icon: "🇫🇷" },
        { value: "German", icon: "🇩🇪" },
        { value: "Indian", icon: "🇮🇳" },
        { value: "Italian", icon: "🇮🇹" },
        { value: "Mexican", icon: "🇲🇽" },
        { value: "Thai", icon: "🇹🇭" },
      ]}
    />
  );
};

export default CountrySelect;
