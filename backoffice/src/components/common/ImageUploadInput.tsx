import React, { useRef, useState } from 'react';
import { Camera, Trash2, Upload, AlertCircle, Loader2 } from 'lucide-react';
import { uploadsApi } from '../../lib/api';

interface ImageUploadInputProps {
  value?: string | null;
  onChange: (image: string | null) => void;
  label?: string;
}

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const resolvePreviewSrc = (val: string): string => {
  if (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('data:')) {
    return val;
  }
  const apiUrl = import.meta.env.VITE_API_URL as string | undefined;
  if (val.startsWith('/') && apiUrl && apiUrl.startsWith('http')) {
    try {
      return `${new URL(apiUrl).origin}${val}`;
    } catch {
      return val;
    }
  }
  return val;
};

export const ImageUploadInput: React.FC<ImageUploadInputProps> = ({
  value,
  onChange,
  label = 'Photo du Produit',
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const processFile = (file: File) => {
    setError(null);
    if (!ALLOWED_TYPES.includes(file.type)) {
      setError('Format invalide : utilisez JPG, PNG ou WebP.');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const maxWidth = 1024;
        const maxHeight = 1024;
        let width = img.width;
        let height = img.height;

        if (width > height && width > maxWidth) {
          height = Math.round((height * maxWidth) / width);
          width = maxWidth;
        } else if (height >= width && height > maxHeight) {
          width = Math.round((width * maxHeight) / height);
          height = maxHeight;
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        ctx.drawImage(img, 0, 0, width, height);
        canvas.toBlob(
          async (blob) => {
            if (!blob) {
              setError('Impossible de préparer l\'image.');
              return;
            }
            setIsUploading(true);
            try {
              const res = await uploadsApi.uploadImage(blob, `${file.name.split('.')[0] || 'product'}.jpg`);
              onChange(res.url);
            } catch {
              setError('Échec du téléversement de l\'image vers le serveur.');
            } finally {
              setIsUploading(false);
            }
          },
          'image/jpeg',
          0.84
        );
      };
      img.src = e.target?.result as string;
    };
    reader.readAsDataURL(file);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) processFile(file);
    e.target.value = '';
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file) processFile(file);
  };

  return (
    <div className="space-y-1.5">
      <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
        {label}
      </label>

      {value ? (
        <div className="relative group w-full h-36 rounded-2xl overflow-hidden border-2 border-brand-200 dark:border-brand-500/30 bg-slate-50 dark:bg-dark-700 flex items-center justify-center shadow-sm">
          <img
            src={resolvePreviewSrc(value)}
            alt="Aperçu produit"
            className="w-full h-full object-contain p-2"
          />
          <div className="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
            <button
              type="button"
              disabled={isUploading}
              onClick={() => fileInputRef.current?.click()}
              className="p-2 rounded-xl bg-white/90 text-slate-800 hover:bg-white text-xs font-bold shadow flex items-center gap-1.5"
            >
              <Upload className="w-3.5 h-3.5" />
              <span>Changer</span>
            </button>
            <button
              type="button"
              disabled={isUploading}
              onClick={() => {
                if (fileInputRef.current) fileInputRef.current.value = '';
                onChange(null);
              }}
              className="p-2 rounded-xl bg-rose-600/90 text-white hover:bg-rose-600 text-xs font-bold shadow flex items-center gap-1.5"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Supprimer</span>
            </button>
          </div>
        </div>
      ) : (
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setIsDragging(true);
          }}
          onDragLeave={() => setIsDragging(false)}
          onDrop={handleDrop}
          onClick={() => !isUploading && fileInputRef.current?.click()}
          className={`w-full h-28 rounded-2xl border-2 border-dashed flex flex-col items-center justify-center p-4 cursor-pointer transition-all ${
            isDragging
              ? 'border-brand-500 bg-brand-50/50 dark:bg-brand-950/20 scale-[0.99]'
              : 'border-slate-300 dark:border-dark-600 hover:border-brand-400 bg-slate-50/60 dark:bg-dark-700'
          }`}
        >
          <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/10 text-brand-600 dark:text-brand-400 flex items-center justify-center mb-1.5">
            {isUploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Camera className="w-4 h-4" />}
          </div>
          <span className="text-xs font-bold text-slate-700 dark:text-slate-300">
            {isUploading ? 'Envoi vers le stockage cloud...' : 'Cliquez ou glissez une photo ici'}
          </span>
          <span className="text-[10px] text-slate-400 mt-0.5">
            PNG, JPG ou WebP (max 2 Mo, compressé avant envoi)
          </span>
        </div>
      )}

      {error && (
        <div className="flex items-center gap-1.5 text-xs text-rose-500 font-medium pt-1">
          <AlertCircle className="w-3.5 h-3.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={handleFileChange}
        className="hidden"
      />
    </div>
  );
};
