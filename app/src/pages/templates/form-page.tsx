import { FieldValues, FormProvider } from "react-hook-form";
import Form, { FormProps } from "./form";
import Page, { PageProps } from "./page";

const FormPage = <T extends FieldValues>({
  children,
  methods,
  onSubmit,
  onError,
  ...pageProps
}: React.PropsWithChildren<FormProps<T> & PageProps>) => (
  <FormProvider {...methods}>
    <Page {...pageProps}>
      <Form methods={methods} onSubmit={onSubmit} onError={onError}>
        {children}
      </Form>
    </Page>
  </FormProvider>
);

export default FormPage;
