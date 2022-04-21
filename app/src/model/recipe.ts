import { add, startOfDay, startOfToday, sub } from "date-fns";
import { z } from "zod";
import { durationSchema } from "./duration";

export const recipeIngredientSchema = z.object({
  amount: z.number().optional(),
  unit: z.string().optional(),
  ingredientName: z.string(),
});
export const recipeInstructionActionSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("step"),
    duration: durationSchema.optional(),
  }),
  z.object({
    type: z.literal("preparation"),
    duration: durationSchema,
  }),
]);

export const recipeInstructionSchema = z.object({
  instruction: z.string(),
  action: recipeInstructionActionSchema,
});
export const recipeFacetSchema = z.object({
  key: z.string(),
  value: z.string(),
  icon: z.string().optional(),
});
export const recipeSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  instructions: z.array(recipeInstructionSchema),
  ingredients: z.array(recipeIngredientSchema),
  facets: z.array(recipeFacetSchema).optional(),
});

export type Recipe = typeof recipeSchema._type;
export type RecipeFacet = typeof recipeFacetSchema._type;
export type RecipeInstruction = typeof recipeInstructionSchema._type;

export function groupInstructionsByDate(
  recipe: Recipe,
  date: number = startOfToday().getTime()
): Record<number, RecipeInstruction[]> {
  const result: Record<number, RecipeInstruction[]> = {};
  for (const instruction of recipe.instructions) {
    let instructionDate: Date;
    switch (instruction.action.type) {
      case "preparation":
        instructionDate = sub(date, instruction.action.duration);
        break;
      default:
        instructionDate = instruction.action.duration
          ? add(date, instruction.action.duration)
          : new Date(date);
        break;
    }

    const d = startOfDay(instructionDate).getTime();
    result[d] = [...(result[d] || []), instruction];
  }

  return result;
}
