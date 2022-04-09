import { Story } from "@storybook/react";
import routerDecorator from "../../../.storybook/decorators/router-decorator";
import Edit from "./edit";

const Default = {
  title: "pages/recipe/Edit",
  component: Edit,
  decorators: [routerDecorator("/recipe/1/edit", "/recipe/:recipeId/edit")],
};

const Template: Story = () => <Edit />;

export const StandardRecipe = Template.bind({});

export default Default;
