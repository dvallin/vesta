import { Story } from "@storybook/react";
import routerDecorator from "../../../.storybook/decorators/router-decorator";
import Add from "./add";

const Default = {
  title: "pages/recipe/Add",
  component: Add,
  decorators: [routerDecorator("/recipe/add", "/recipe/add")],
};

const Template: Story = () => <Add />;

export const StandardRecipe = Template.bind({});

export default Default;
