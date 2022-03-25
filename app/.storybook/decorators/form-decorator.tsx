import { Story } from "@storybook/react";
import {
  FieldValues,
  FormProvider,
  useForm,
  UseFormProps,
} from "react-hook-form";

export default function formDecorator<T extends FieldValues>(
  props?: UseFormProps<T>
) {
  return (Story: Story) => (
    <FormProvider {...useForm<T>(props)}>
      <Story />
    </FormProvider>
  );
}
