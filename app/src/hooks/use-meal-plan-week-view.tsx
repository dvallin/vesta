import { useMemo } from "react";
import { DailyMealPlan, buildPlanItems } from "../model/meal-plan";
import { useMealPlan } from "../storage/use-meal-plan";
import { useRecipes } from "../storage/use-recipes";

export default function useMealPlanWeekView() {
  const { data } = useMealPlan();
  const { data: recipes } = useRecipes();
  return useMemo(
    () => buildPlanItems<DailyMealPlan>(data?.plans ?? [], recipes),
    [data, recipes]
  );
}
