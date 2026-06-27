// Button.tsx -- primary interactive trigger
// Token dependencies: color-primary-500 (background), color-danger-500 (destructive variant)
// Variants: primary, secondary, destructive, ghost
import React from 'react';
import { ButtonProps } from './Button.types';

export const Button: React.FC<ButtonProps> = ({ label, variant = 'primary', disabled = false }) => {
  return (
    <button
      className={`btn btn--${variant}`}
      disabled={disabled}
      aria-disabled={disabled}
    >
      {label}
    </button>
  );
};
