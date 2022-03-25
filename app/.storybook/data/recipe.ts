import { Entity } from "../../src/model/entity";
import { Recipe } from "../../src/model/recipe";
import { loremIpsum } from "./lorem-ipsum";
import { SwrCache, createCache } from "./swr-cache";

export const standardRecipe: Entity<Recipe> = {
  id: "1",
  name: loremIpsum(4),
  description: loremIpsum(30),
  instructions: [
    {
      instruction: loremIpsum(30),
      action: {
        type: "preparation",
        duration: { days: 1, hours: 0, minutes: 0 },
      },
    },
    {
      instruction: loremIpsum(30),
      action: {
        type: "preparation",
        duration: { days: 0, hours: 3, minutes: 0 },
      },
    },
    { instruction: loremIpsum(30), action: { type: "step" } },
    { instruction: loremIpsum(30), action: { type: "step" } },
    { instruction: loremIpsum(30), action: { type: "step" } },
    { instruction: loremIpsum(30), action: { type: "step" } },
  ],
  ingredients: [
    { ingredientName: "potato", amount: 1, unit: "kg" },
    { ingredientName: "mayonnaise", amount: 12.3, unit: "g" },
    { ingredientName: "tomatoes", amount: 10 },
    { ingredientName: "salt" },
  ],
};

export const recipes: () => SwrCache = () =>
  createCache(["recipes", [standardRecipe]]);
