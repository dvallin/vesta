import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { MealPlan, mealPlanSchema } from "../../../model/meal-plan";
import { AbstractType } from "yjs";
import { getYjsValue } from "@syncedstore/core";
import { useMealPlan } from "../../../storage/use-meal-plan";
import { useIonRouter } from "@ionic/react";

export default function useEdit() {
  const mealPlan = useMealPlan();
  const value = getYjsValue(mealPlan) as AbstractType<MealPlan> | undefined;

  const methods = useForm<MealPlan>({
    mode: "all",
    resolver: zodResolver(mealPlanSchema),
    defaultValues: value?.toJSON() as MealPlan,
  });

  const router = useIonRouter();

  return {
    methods,
    onSubmit: (updated: MealPlan) => {
      mealPlan.plans = updated.plans;
      router.goBack();
    },
  };
}
