import { Entity } from "../model/entity";
import { MealPlan } from "../model/meal-plan";
import { getSingleton, update, add } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

const defaultValue: MealPlan = { plans: [] };

export function useMealPlan() {
  return useSwrRepository(
    "meal-plan",
    async () => getSingleton<MealPlan>("meal-plan", defaultValue),
    {
      add: async (plan: MealPlan) => add("meal-plan", plan),
      update: async (plan: Entity<MealPlan>) => update(plan),
    }
  );
}
