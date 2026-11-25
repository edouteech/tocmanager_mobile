import React from 'react';
import { Link } from 'react-router-dom';
import { buildSurfaceUrl, isExternalSurfaceUrl, TargetSurface } from '../../lib/domainRouting';

interface SurfaceLinkProps {
  surface: TargetSurface;
  to: string;
  className?: string;
  onClick?: React.MouseEventHandler<HTMLAnchorElement>;
  target?: string;
  rel?: string;
  'aria-label'?: string;
  children: React.ReactNode;
}

/**
 * Link across subdomains cleanly using <a> for external origins and React Router <Link> locally.
 */
export const SurfaceLink: React.FC<SurfaceLinkProps> = ({
  surface,
  to,
  className,
  onClick,
  target,
  rel,
  'aria-label': ariaLabel,
  children,
}) => {
  const resolved = buildSurfaceUrl(surface, to);

  if (isExternalSurfaceUrl(resolved)) {
    return (
      <a
        href={resolved}
        className={className}
        onClick={onClick}
        target={target}
        rel={rel}
        aria-label={ariaLabel}
      >
        {children}
      </a>
    );
  }

  return (
    <Link
      to={resolved}
      className={className}
      onClick={onClick}
      target={target}
      rel={rel}
      aria-label={ariaLabel}
    >
      {children}
    </Link>
  );
};
