import { syncedStore, getYjsValue } from "@syncedstore/core";
import { DocTypeDescription } from "@syncedstore/core/types/doc";
import { IndexeddbPersistence } from "y-indexeddb";
import { WebrtcProvider } from "y-webrtc";
import { Doc } from "yjs";
import { Entity } from "../model/entity";
import { MealPlan } from "../model/meal-plan";
import { Recipe } from "../model/recipe";
import { ShoppingList } from "../model/shopping-list";

export interface State extends DocTypeDescription {
  mealPlan: MealPlan;
  shoppingList: ShoppingList;
  recipes: Entity<Recipe>[];
}

export const store = syncedStore<State>({
  mealPlan: {} as MealPlan,
  shoppingList: {} as ShoppingList,
  recipes: [],
});

const doc = getYjsValue(store) as Doc;
export const webrtcProvider = new WebrtcProvider("vesta-default-room", doc);
export const indexeddbProvider = new IndexeddbPersistence("vesta-state", doc);
