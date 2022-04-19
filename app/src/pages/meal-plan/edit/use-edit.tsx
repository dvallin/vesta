import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { MealPlan, mealPlanSchema } from "../../../model/meal-plan";
import { useMealPlan } from "../../../storage/use-meal-plan";
import { useIonRouter } from "@ionic/react";
import { toJson } from "../../../storage/to-json";

export default function useEdit() {
  const mealPlan = useMealPlan();

  const methods = useForm<MealPlan>({
    mode: "all",
    resolver: zodResolver(mealPlanSchema),
    defaultValues: toJson(mealPlan),
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
