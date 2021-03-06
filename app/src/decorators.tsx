import { renderHook } from "@testing-library/react-hooks";
import { ReactElement } from "react";
import {
  FieldValues,
  FormProvider,
  useForm,
  UseFormProps,
} from "react-hook-form";

export type Decorator = (children: ReactElement) => ReactElement;
type Decorators = readonly Decorator[];

// Recursively wraps component around given decorators
function wrapWithDecorator(
  children: ReactElement,
  decorators: Decorators,
  index: number
): ReactElement {
  if (index === -1) {
    return children;
  }

  return wrapWithDecorator(decorators[index](children), decorators, index - 1);
}

// Use this function instead of RHTLs renderHook function if you need to wrap your components with decorators
export function renderHookWithDecorators<P, R>(
  callback: (props: P) => R,
  initialProps?: P,
  decorators?: Decorators
) {
  return renderHook<P, R>(callback, {
    initialProps,
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    wrapper: decorators
      ? ({ children }: { children: ReactElement }) =>
          wrapWithDecorator(children, decorators, decorators.length - 1)
      : undefined,
  });
}

/**
 * Provides a react hook form context.
 */
export const formDecorator = <T extends FieldValues>(
  props?: UseFormProps<T>
): Decorator =>
  function (component) {
    const methods = useForm<T>(props);
    return <FormProvider {...methods}>{component}</FormProvider>;
  };
