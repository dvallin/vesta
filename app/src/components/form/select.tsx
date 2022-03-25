import { IonLabel, IonSelect, IonSelectOption } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

export interface SelectProps {
  name: string;
  label?: string;
  options: Array<{ value: string; label: string }>;
}

const Select: React.FC<SelectProps> = ({ name, label, options }) => {
  const { control } = useFormContext();
  return (
    <Controller
      key={name}
      control={control}
      name={name}
      render={({ field }) => (
        <>
          {label && <IonLabel position="stacked">{label}</IonLabel>}
          <IonSelect
            value={field.value as string}
            onIonChange={({ detail }) => {
              field.onChange(detail.value);
            }}
          >
            {options.map(({ value, label }) => (
              <IonSelectOption key={value} value={value}>
                {label}
              </IonSelectOption>
            ))}
          </IonSelect>
        </>
      )}
    />
  );
};

export default Select;
