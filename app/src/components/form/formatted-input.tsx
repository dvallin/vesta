import { IonInput, IonLabel } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

export type IonInputProps = React.ComponentProps<typeof IonInput>;
export interface FormattedInputProps<T>
  extends Omit<IonInputProps, "value" | "onIonChange"> {
  parse: (v: string) => T | undefined;
  format: (v: T) => string;
  name: string;
  label?: string;
}

// eslint-disable-next-line @typescript-eslint/comma-dangle
const FormattedInput = <T,>({
  parse,
  format,
  name,
  label,
  ...ionInputProps
}: FormattedInputProps<T>) => {
  const { control } = useFormContext();
  return (
    <Controller
      key={name}
      control={control}
      name={name}
      render={({ field: { value, onChange } }) => (
        <>
          {label && <IonLabel position="stacked">{label}</IonLabel>}
          <IonInput
            // eslint-disable-next-line unicorn/no-null
            value={value ? format(value as T) : null}
            onIonChange={({ detail }) => {
              if (detail.value) {
                const v = parse(detail.value);
                if (v) {
                  onChange(v);
                }
              } else {
                // eslint-disable-next-line unicorn/no-null
                onChange(null);
              }
            }}
            {...ionInputProps}
          />
        </>
      )}
    />
  );
};

export default FormattedInput;
