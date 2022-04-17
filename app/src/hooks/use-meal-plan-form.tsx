import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { MealPlan, mealPlanSchema } from "../model/meal-plan";
import { AbstractType } from "yjs";
import { getYjsValue } from "@syncedstore/core";
import { useMealPlan } from "../storage/use-meal-plan";

export default function useMealPlanForm() {
  const mealPlan = useMealPlan();
  const value = getYjsValue(mealPlan) as AbstractType<MealPlan> | undefined;

  const methods = useForm<MealPlan>({
    mode: "all",
    resolver: zodResolver(mealPlanSchema),
    defaultValues: value?.toJSON() as MealPlan,
  });

  return methods;
}
