import { Story } from "@storybook/react";
import swrDecorator from "../../../.storybook/decorators/swr-decorator";
import Edit from "./edit";

const Default = {
  title: "pages/shopping-list/Edit",
  component: Edit,
  decorators: [swrDecorator()],
};

const Template: Story = () => <Edit />;

export const StandardRecipe = Template.bind({});

export default Default;
