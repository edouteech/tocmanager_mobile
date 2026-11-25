import React from 'react';

export type BrandLogoVariant = 'full' | 'icon';
export type BrandLogoSize = 'sm' | 'md' | 'lg';

interface BrandLogoAssetConfig {
  src: string;
  width: number;
  height: number;
}

const BRAND_LOGO_ASSETS: Record<BrandLogoVariant, BrandLogoAssetConfig> = {
  full: { src: '/assets/logo.png', width: 500, height: 85 },
  icon: { src: '/assets/icon.png', width: 499, height: 499 },
};

const BRAND_LOGO_SIZES: Record<BrandLogoVariant, Record<BrandLogoSize, string>> = {
  full: {
    sm: 'h-6 w-auto',
    md: 'h-7 sm:h-8 w-auto',
    lg: 'h-9 sm:h-10 w-auto',
  },
  icon: {
    sm: 'h-8 w-8',
    md: 'h-10 w-10',
    lg: 'h-14 w-14',
  },
};

export interface BrandLogoProps {
  variant?: BrandLogoVariant;
  size?: BrandLogoSize;
  alt?: string;
  priority?: boolean;
  className?: string;
}

/**
 * Render the official TocManager brand logo shared with the mobile application.
 */
export const BrandLogo: React.FC<BrandLogoProps> = ({
  variant = 'full',
  size = 'md',
  alt = 'TocManager',
  priority = false,
  className = '',
}) => {
  const asset = BRAND_LOGO_ASSETS[variant];
  const sizeClass = BRAND_LOGO_SIZES[variant][size];

  return (
    <img
      src={asset.src}
      alt={alt}
      width={asset.width}
      height={asset.height}
      loading={priority ? 'eager' : 'lazy'}
      decoding="async"
      className={`max-w-full object-contain select-none shrink-0 ${sizeClass} ${className}`.trim()}
    />
  );
};
