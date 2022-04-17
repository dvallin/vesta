import { getYjsValue } from "@syncedstore/core";
import { useMemo } from "react";
import { AbstractType } from "yjs";
import { DailyMealPlan, buildPlanItems, MealPlan } from "../model/meal-plan";
import { useMealPlan } from "../storage/use-meal-plan";
import { useRecipes } from "../storage/use-recipes";

export default function useMealPlanWeekView() {
  const mealPlan = useMealPlan();
  const { data: recipes } = useRecipes();
  const value = getYjsValue(mealPlan) as AbstractType<MealPlan> | undefined;
  const { plans } = value?.toJSON() as MealPlan;
  return useMemo(
    () => buildPlanItems<DailyMealPlan>(plans ?? [], recipes),
    [plans, recipes]
  );
}
