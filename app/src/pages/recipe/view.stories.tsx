import { Story } from "@storybook/react";
import routerDecorator from "../../../.storybook/decorators/router-decorator";
import View from "./view";

const Default = {
  title: "pages/recipe/View",
  component: View,
  decorators: [routerDecorator("/recipe/1", "/recipe/:recipeId")],
};

const Template: Story = () => <View />;

export const StandardRecipe = Template.bind({});

export default Default;
