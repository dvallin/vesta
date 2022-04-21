import FacetEdit from "./facet-edit";

const CountryEdit = () => (
  <FacetEdit
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

export default CountryEdit;
