import { useEffect } from "react";
import { FieldValues } from "react-hook-form";
import Form, { FormProps } from "./form";
import Page, { PageProps } from "./page";

const SynchFormPage = <T extends FieldValues>({
  children,
  methods,
  onSubmit,
  onError,
  ...pageProps
}: React.PropsWithChildren<FormProps<T> & PageProps>) => {
  useEffect(() => {
    if (methods.formState.isDirty) {
      void methods.handleSubmit(onSubmit)();
    }
  }, [methods, onSubmit]);

  return (
    <Page {...pageProps}>
      <Form methods={methods} onSubmit={onSubmit} onError={onError}>
        {children}
      </Form>
    </Page>
  );
};

export default SynchFormPage;
