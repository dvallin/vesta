import { MealPlan } from "../model/meal-plan";
import { getFirstByType, update, add } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

export function useMealPlan() {
  return useSwrRepository(
    "meal-plan",
    async () => getFirstByType<MealPlan>("meal-plan"),
    {
      add: async (plan: MealPlan) => add("meal-plan", plan),
      update: async (id: string, plan: MealPlan) => update(id, plan),
    }
  );
}
