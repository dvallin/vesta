import { Story } from "@storybook/react";
import routerDecorator from "../../../.storybook/decorators/router-decorator";
import swrDecorator from "../../../.storybook/decorators/swr-decorator";
import Search from "./search";

const Default = {
  title: "pages/recipe/Search",
  component: Search,
  decorators: [swrDecorator(), routerDecorator()],
};

const Template: Story = () => <Search />;

export const StandardRecipe = Template.bind({});

export default Default;
