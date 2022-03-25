import { IonInput, IonLabel } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

export type IonInputProps = React.ComponentProps<typeof IonInput>;
export interface InputProps
  extends Omit<IonInputProps, "value" | "onIonChange" | "type"> {
  name: string;
  label?: string;
}

const NumberInput: React.FC<InputProps> = ({
  name,
  label,
  ...ionInputProps
}) => {
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
            type="number"
            onIonChange={({ detail }) => {
              field.onChange(detail.value && Number.parseFloat(detail.value));
            }}
            {...ionInputProps}
          />
        </>
      )}
    />
  );
};

export default NumberInput;
