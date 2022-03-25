import { IonInput, IonLabel } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

export type IonInputProps = React.ComponentProps<typeof IonInput>;
export interface InputProps
  extends Omit<IonInputProps, "value" | "onIonChange"> {
  name: string;
  label?: string;
}

const Input: React.FC<InputProps> = ({ name, label, ...ionInputProps }) => {
  const { control } = useFormContext();
  return (
    <Controller
      key={name}
      control={control}
      name={name}
      render={({ field }) => (
        <>
          {label && <IonLabel position="stacked">{label}</IonLabel>}
          <IonInput
            value={field.value as string}
            onIonChange={({ detail }) => {
              field.onChange(detail.value);
            }}
            {...ionInputProps}
          />
        </>
      )}
    />
  );
};

export default Input;
