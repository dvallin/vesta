import SuggestionInput, { SuggestionInputProps } from "./suggestion-input";

const UnitInput: React.FC<
  Omit<SuggestionInputProps, "label" | "type" | "suggestions">
> = (props) => (
  <SuggestionInput
    {...props}
    label="Unit"
    type="text"
    suggestions={[
      // Volume
      "tsp.", // Teaspoon (t or tsp.)
      "tbsp.", // Tablespoon (T, tbl., tbs., or tbsp.)
      "fl oz", // Fluid ounce
      "cup", // C
      "pint", // P, pt, or fl pt
      "quart", //  Q, qt, or fl qt
      "gallon", // G or gal
      "ml", // Milliliter, millilitre, cc, mL
      "l", // Liter, litre, L
      "dl", // Deciliter, decilitre, dL
      "cl", // Centiliter, centilitre, cL
      // gram
      "lb", // Pound
      "oz", // Ounce
      "mg",
      "g",
      "kg",
      // Length
      "mm", // Pound
      "cm", // Ounce
      "m",
      "inch",
    ]}
  />
);

export default UnitInput;
