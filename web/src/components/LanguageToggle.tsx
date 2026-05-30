import { useTranslation } from 'react-i18next'
import { SUPPORTED_LANGUAGES, type Language } from '../i18n'

interface Props {
  /** 'light' for use on the green header, 'dark' for white backgrounds. */
  variant?: 'light' | 'dark'
}

export function LanguageToggle({ variant = 'dark' }: Props) {
  const { i18n, t } = useTranslation()
  const current = (i18n.resolvedLanguage ?? 'en') as Language

  const base =
    variant === 'light'
      ? 'border-white/30 text-white/80'
      : 'border-slate-200 text-slate-400'
  const activeCls =
    variant === 'light'
      ? 'bg-white/20 text-white'
      : 'bg-brand-500 text-white'

  return (
    <div
      role="group"
      aria-label={t('language.label')}
      className={`inline-flex overflow-hidden rounded-md border text-xs font-semibold ${base}`}
    >
      {SUPPORTED_LANGUAGES.map((lng) => (
        <button
          key={lng}
          type="button"
          onClick={() => i18n.changeLanguage(lng)}
          aria-pressed={current === lng}
          className={`px-2.5 py-1 transition ${
            current === lng ? activeCls : 'hover:opacity-100'
          }`}
        >
          {t(`language.${lng}`)}
        </button>
      ))}
    </div>
  )
}
