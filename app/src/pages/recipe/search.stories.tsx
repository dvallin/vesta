import { Story } from "@storybook/react";
import routerDecorator from "../../../.storybook/decorators/router-decorator";
import Search from "./search";

const Default = {
  title: "pages/recipe/Search",
  component: Search,
  decorators: [routerDecorator()],
};

const Template: Story = () => <Search />;

export const StandardRecipe = Template.bind({});

export default Default;
