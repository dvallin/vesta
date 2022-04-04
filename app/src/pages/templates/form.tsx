import { useEffect } from "react";
import {
  FieldValues,
  FormProvider,
  SubmitErrorHandler,
  SubmitHandler,
  UseFormReturn,
} from "react-hook-form";
import useToolbar from "../../hooks/use-toolbar";

export interface FormProps<T extends FieldValues> {
  methods: UseFormReturn<T>;
  onSubmit: SubmitHandler<T>;
  onError?: SubmitErrorHandler<T>;
}

const Form = <T extends FieldValues>({
  methods,
  onSubmit,
  onError,
  children,
}: React.PropsWithChildren<FormProps<T>>) => {
  const { register } = useToolbar();
  useEffect(() => {
    register("handle-submit", (key) => {
      if (key === "submit") {
        void methods.handleSubmit(onSubmit)();
      }
    });
  }, [methods, onSubmit, register]);

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit, onError)}>{children}</form>
    </FormProvider>
  );
};

export default Form;
