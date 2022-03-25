import { Story } from "@storybook/react";
import pageDecorator from "../../../.storybook/decorators/page-decorator";
import formDecorator from "../../../.storybook/decorators/form-decorator";
import { Recipe } from "../../model/recipe";
import Form from "./form";

const Default = {
  title: "molecules/meal-plan/Form",
  component: Form,
  args: {
    onSubmit(recipe: Recipe) {
      console.log("submitted", recipe);
    },
  },
  decorators: [pageDecorator, formDecorator()],
};

const Template: Story = (args) => <Form {...args} />;

export const StandardRecipe = Template.bind({});

export default Default;
