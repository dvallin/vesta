import { Story } from "@storybook/react";
import AddMealPlan from "./add-meal-plan";

const Default = {
  title: "pages/shopping-list/AddMealPlan",
  component: AddMealPlan,
  decorators: [],
};

const Template: Story = () => <AddMealPlan />;

export const StandardRecipe = Template.bind({});

export default Default;
