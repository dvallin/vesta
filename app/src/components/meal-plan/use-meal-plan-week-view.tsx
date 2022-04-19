import { useMemo } from "react";
import { DailyMealPlan, buildPlanItems } from "../../model/meal-plan";
import { toJson } from "../../storage/to-json";
import { useMealPlan } from "../../storage/use-meal-plan";
import { useRecipes } from "../../storage/use-recipes";

export default function useMealPlanWeekView() {
  const mealPlan = useMealPlan();
  const { data: recipes } = useRecipes();
  const { plans } = toJson(mealPlan);
  return useMemo(
    () => buildPlanItems<DailyMealPlan>(plans ?? [], recipes),
    [plans, recipes]
  );
}
