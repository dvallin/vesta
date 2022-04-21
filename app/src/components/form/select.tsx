import { IonSelect, IonSelectOption } from "@ionic/react";
import { Controller, useFormContext } from "react-hook-form";

type IonSelectProps = React.ComponentProps<typeof IonSelect>;
export interface SelectProps extends IonSelectProps {
  name: string;
  options: Array<{ value: string; label: string }>;
}

const Select: React.FC<SelectProps> = ({
  name,
  options,
  ...ionSelectProps
}) => {
  const { control } = useFormContext();
  return (
    <Controller
      key={name}
      control={control}
      name={name}
      render={({ field }) => (
        <>
          <IonSelect
            value={field.value as string}
            onIonChange={({ detail }) => {
              field.onChange(detail.value);
            }}
            {...ionSelectProps}
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
