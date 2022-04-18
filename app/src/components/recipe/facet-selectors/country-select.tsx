import FacetSelect from "./facet-select";

const CountrySelect = () => (
  <FacetSelect
    facetKey="country"
    placeholder="Country"
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

export default CountrySelect;
