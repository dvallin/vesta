import { IonCol, IonGrid, IonItem, IonRow, IonSearchbar } from "@ionic/react";
import { Recipe } from "../../../model/recipe";
import { Entity } from "../../../model/entity";
import RecipeList from "../list";
import useSearch from "./use-search";
import CountrySelect from "../facets/select/country-select";
import DietSelect from "../facets/select/diet-select";

export interface RecipeSearchProps {
  maxCount?: number;
  onSelect: (recipe: Entity<Recipe>) => void;
}

const RecipeSearch: React.FC<RecipeSearchProps> = ({ onSelect, maxCount }) => {
  const { result, term, setTerm, facetQuery, setFacetQuery } =
    useSearch(maxCount);
  return (
    <>
      <IonSearchbar
        value={term}
        onIonChange={({ detail: { value } }) => {
          if (value) {
            setTerm(value);
          }
        }}
      />
      <IonGrid>
        <IonRow>
          <IonCol size="6">
            <IonItem lines="none">
              <CountrySelect
                currentFacets={facetQuery}
                onChange={setFacetQuery}
              />
            </IonItem>
          </IonCol>
          <IonCol size="6">
            <IonItem lines="none">
              <DietSelect currentFacets={facetQuery} onChange={setFacetQuery} />
            </IonItem>
          </IonCol>
        </IonRow>
      </IonGrid>
      <RecipeList recipes={result} onClick={onSelect} />
    </>
  );
};

export default RecipeSearch;
