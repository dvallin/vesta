import { useSyncedStore } from "@syncedstore/react";
import { store } from "./store";

export function useMealPlan() {
  return useSyncedStore(store).mealPlan;
}
