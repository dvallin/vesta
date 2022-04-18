import FacetSelect from "./facet-select";

const DietSelect = () => (
  <FacetSelect
    multiple
    facetKey="diet"
    placeholder="Diet"
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

export default DietSelect;
