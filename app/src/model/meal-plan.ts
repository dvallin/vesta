import { z } from "zod";
import { DayItem, getWeekList, WeekItem } from "../week";
import { Entity } from "./entity";
import { groupInstructionsByDate, Recipe, RecipeInstruction } from "./recipe";

export const dailyMealPlanSchema = z.object({
  date: z.number(),
  recipeId: z.string(),
});
export const mealPlanSchema = z.object({
  plans: z.array(dailyMealPlanSchema),
});

export type MealPlan = typeof mealPlanSchema._type;
export type DailyMealPlan = typeof dailyMealPlanSchema._type;

export type MealItem<P extends DailyMealPlan = DailyMealPlan> = {
  type: "meal";
  date: number;
  instructions: RecipeInstruction[];
  index: number;
  plan: P;
};
export type PreparationItem<P extends DailyMealPlan = DailyMealPlan> = {
  type: "preparation";
  date: number;
  instructions: RecipeInstruction[];
  plan: P;
};

export type MealPlanItem<P extends DailyMealPlan = DailyMealPlan> =
  | MealItem<P>
  | PreparationItem<P>
  | WeekItem
  | DayItem;

export function buildPlanItems<P extends DailyMealPlan>(
  plans: P[],
  recipes?: Array<Entity<Recipe>>
) {
  const items = plans
    // FIXME: leaky abstraction in syncedstore - missing flatMap
    // eslint-disable-next-line unicorn/prefer-array-flat-map
    .map((plan, index) => {
      const recipe = recipes?.find((r) => r.id === plan.recipeId);
      const instructionsByDate = recipe
        ? groupInstructionsByDate(recipe, plan.date)
        : {};
      const result = Object.entries(instructionsByDate).map(
        ([d, instructions]) => {
          const date = Number.parseInt(d, 10);
          if (date !== plan.date) {
            const item: PreparationItem<P> = {
              type: "preparation",
              date,
              instructions,
              plan,
            };
            return item;
          }

          const item: MealItem<P> = {
            type: "meal",
            date,
            instructions,
            index,
            plan,
          };
          return item;
        }
      );
      if (!instructionsByDate[plan.date]) {
        result.push({
          type: "meal",
          date: plan.date,
          instructions: recipe?.instructions ?? [],
          index,
          plan,
        } as MealItem<P>);
      }

      return result;
    })
    .flat();

  const week = getWeekList();
  return week.flatMap<MealPlanItem<P>>((item) =>
    item.type === "week"
      ? [item]
      : [
          // A day placeholder
          item,
          // All meals of this day
          ...items.filter(({ date }) => date === item.date),
        ]
  );
}
