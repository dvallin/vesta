import { IonLabel, IonTextarea } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

export type IonTextareaProps = React.ComponentProps<typeof IonTextarea>;
export interface InputProps
  extends Omit<IonTextareaProps, "value" | "onIonChange"> {
  name: string;
  label?: string;
}

const TextArea: React.FC<InputProps> = ({ name, label, ...ionInputProps }) => {
  const { control } = useFormContext();
  return (
    <Controller
      control={control}
      name={name}
      render={({ field }) => (
        <>
          {label && <IonLabel position="stacked">{label}</IonLabel>}
          <IonTextarea
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

export default TextArea;
