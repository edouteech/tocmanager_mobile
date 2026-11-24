import React from 'react';

export interface IconInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  icon: React.ReactNode;
  rightSlot?: React.ReactNode;
  containerClassName?: string;
  iconClassName?: string;
}

export const IconInput = React.forwardRef<HTMLInputElement, IconInputProps>(
  (
    {
      icon,
      rightSlot,
      containerClassName = '',
      iconClassName = '',
      className = '',
      ...inputProps
    },
    ref
  ) => (
    <div className={`relative ${containerClassName}`.trim()}>
      <span
        aria-hidden="true"
        className={`pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-[#9FB3C8] dark:text-slate-400 ${iconClassName}`.trim()}
      >
        {icon}
      </span>
      <input
        ref={ref}
        className={`input-toc pl-10 ${rightSlot ? 'pr-20' : ''} ${className}`.trim()}
        {...inputProps}
      />
      {rightSlot && (
        <div className="absolute inset-y-0 right-0 flex items-center pr-3">
          {rightSlot}
        </div>
      )}
    </div>
  )
);

IconInput.displayName = 'IconInput';
