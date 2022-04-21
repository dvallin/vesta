import FacetEdit from "./facet-edit";

const DietEdit = () => (
  <FacetEdit
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

export default DietEdit;
