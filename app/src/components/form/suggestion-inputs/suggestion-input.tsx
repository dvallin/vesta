import { IonInput, IonItem, IonLabel, IonList, IonPopover } from "@ionic/react";
import { Controller, useFormContext, useWatch } from "react-hook-form";
import useSearch from "../../../hooks/use-search";

export type IonInputProps = React.ComponentProps<typeof IonInput>;
export interface SuggestionInputProps
  extends Omit<IonInputProps, "value" | "onIonChange"> {
  name: string;
  label?: string;
  suggestions: string[];
}

const SuggestionInput: React.FC<SuggestionInputProps> = ({
  name,
  label,
  suggestions,
  ...ionInputProps
}) => {
  const { control } = useFormContext();
  const value = useWatch({ name, control }) as string | undefined;
  const hits = useSearch(value ?? "", suggestions, { maxCount: 3 });
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
            id={`trigger-${field.name}`}
            onIonChange={({ detail }) => {
              field.onChange(detail.value);
            }}
            {...ionInputProps}
          />
          <IonPopover
            dismissOnSelect
            trigger={`trigger-${field.name}`}
            showBackdrop={false}
            keyboardClose={false}
            size="cover"
          >
            <IonList>
              {hits.map((hit) => (
                <IonItem
                  key={hit}
                  button
                  lines="none"
                  onClick={() => {
                    field.onChange(hit);
                  }}
                >
                  <IonLabel>{hit}</IonLabel>
                </IonItem>
              ))}
            </IonList>
          </IonPopover>
        </>
      )}
    />
  );
};

export default SuggestionInput;
