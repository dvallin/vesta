import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { MealPlan, mealPlanSchema } from "../model/meal-plan";

export default function useMealPlanForm(plan?: MealPlan) {
  const methods = useForm<MealPlan>({
    mode: "all",
    resolver: zodResolver(mealPlanSchema),
  });

  useEffect(() => {
    if (plan) {
      methods.reset(plan);
    }
  }, [plan, methods]);

  return methods;
}
