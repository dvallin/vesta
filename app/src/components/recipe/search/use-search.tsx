import { useRecipes } from "../../../storage/use-recipes";
import useGeneralSearch from "../../../hooks/use-search";
import { useState } from "react";
import { Entity } from "../../../model/entity";
import { Recipe, RecipeFacet } from "../../../model/recipe";
import Fuse from "fuse.js";
import { toJson } from "../../../storage/to-json";

export default function useSearch(maxCount?: number) {
  const [term, setTerm] = useState("");
  const [facetQuery, setFacetQuery] = useState<RecipeFacet[]>([]);
  const { data: recipes } = useRecipes();

  const expressions: Fuse.Expression[] = [];

  if (term.length > 0) {
    expressions.push({
      $or: [{ name: term }, { "ingredients.ingredientName": term }],
    });
  }
  if (facetQuery.length > 0) {
    const facetsByKey: { [key: string]: string[] } = {};
    for (const facet of facetQuery) {
      if (!facetsByKey[facet.key]) {
        facetsByKey[facet.key] = [];
      }
      facetsByKey[facet.key].push(facet.value);
    }

    // all facet groups must match (first and)
    // inside a group one should match (first or)
    // inside a facet key and value must match (second and)
    expressions.push({
      $and: Object.entries(facetsByKey).map(([key, values]) => ({
        $or: values.map((value) => ({
          $and: [
            { "facets.key": key } as Fuse.Expression,
            { "facets.value": value } as Fuse.Expression,
          ],
        })),
      })),
    });
  }

  const { result, fullResult } = useGeneralSearch(
    expressions.length > 0
      ? {
          $and: expressions,
        }
      : undefined,
    toJson(recipes) as Entity<Recipe>[],
    {
      maxCount,
      keys: [
        "name",
        "ingredients.ingredientName",
        "facets.key",
        "facets.value",
      ],
    }
  );

  return {
    result,

    setTerm,
    term,

    facets: fullResult.flatMap((r) => r.facets || []),
    facetQuery,
    setFacetQuery,
  };
}
