import { IonInput, IonItem, IonLabel, IonList, IonPopover } from "@ionic/react";
import {
  Controller,
  ControllerRenderProps,
  FieldValues,
  useFormContext,
} from "react-hook-form";
import useSearch from "../../../hooks/use-search";

export type IonInputProps = React.ComponentProps<typeof IonInput>;
export interface SuggestionInputProps
  extends Omit<IonInputProps, "value" | "onIonChange"> {
  name: string;
  label?: string;
  suggestions: string[];
}

interface InnerSuggestionInputProps
  extends Omit<IonInputProps, "value" | "onIonChange"> {
  field: ControllerRenderProps<FieldValues, string>;
  label?: string;
  suggestions: string[];
}

const InnerSuggestionInput: React.FC<InnerSuggestionInputProps> = ({
  field,
  label,
  suggestions,
  ...ionInputProps
}) => {
  const hits = useSearch((field.value as string) ?? "", suggestions, {
    maxCount: 3,
  });
  return (
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
        triggerAction="context-menu"
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
  );
};

const SuggestionInput: React.FC<SuggestionInputProps> = ({
  name,
  label,
  suggestions,
  ...ionInputProps
}) => {
  const { control } = useFormContext();
  return (
    <Controller
      control={control}
      name={name}
      render={({ field }) => (
        <InnerSuggestionInput
          label={label}
          suggestions={suggestions}
          field={field}
          {...ionInputProps}
        />
      )}
    />
  );
};

export default SuggestionInput;
