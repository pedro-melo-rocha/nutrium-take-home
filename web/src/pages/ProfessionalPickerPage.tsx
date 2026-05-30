import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useNavigate } from 'react-router-dom'
import { useNutritionistSearch } from '../api/nutritionists'
import { LanguageToggle } from '../components/LanguageToggle'
import { Logo } from '../components/Logo'
import { Spinner } from '../components/Spinner'
import { ArrowRightIcon, ChevronDownIcon } from '../components/icons'

export default function ProfessionalPickerPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { data, isLoading, isError } = useNutritionistSearch({
    location: 'Braga',
    per_page: 50,
  })
  const [selectedId, setSelectedId] = useState('')

  const nutritionists = data?.results ?? []

  function handleGo() {
    if (selectedId) navigate(`/nutritionists/${selectedId}/requests`)
  }

  return (
    <div className="flex min-h-screen flex-col">
      <header className="bg-white shadow-sm">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
          <Link to="/">
            <Logo className="text-brand-600" />
          </Link>
          <div className="flex items-center gap-3">
            <Link
              to="/"
              className="text-sm font-medium text-slate-500 transition hover:text-slate-700"
            >
              {t('common.backToSearch')}
            </Link>
            <LanguageToggle />
          </div>
        </div>
      </header>

      <main className="flex flex-1 items-center justify-center px-4 py-12">
        <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
          <h1 className="text-xl font-semibold text-slate-800">
            {t('picker.title')}
          </h1>
          <p className="mt-1 text-sm text-slate-500">{t('picker.subtitle')}</p>

          <div className="mt-6 flex flex-col gap-4">
            <label className="flex flex-col gap-1.5 text-sm font-medium text-slate-700">
              {t('picker.nutritionist')}
              {isLoading ? (
                <span className="flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-400">
                  <Spinner className="size-4" /> {t('common.loading')}
                </span>
              ) : isError ? (
                <span className="rounded-lg bg-red-50 px-3 py-2.5 text-sm text-red-600">
                  {t('picker.loadError')}
                </span>
              ) : (
                <div className="relative">
                  <select
                    value={selectedId}
                    onChange={(e) => setSelectedId(e.target.value)}
                    className="input w-full appearance-none pr-10"
                  >
                    <option value="" disabled>
                      {t('picker.choosePlaceholder')}
                    </option>
                    {nutritionists.map((n) => (
                      <option key={n.id} value={n.id}>
                        {n.name}
                        {n.title ? ` · ${n.title}` : ''}
                      </option>
                    ))}
                  </select>
                  <ChevronDownIcon className="pointer-events-none absolute right-3 top-1/2 size-5 -translate-y-1/2 text-slate-400" />
                </div>
              )}
            </label>

            <button
              type="button"
              disabled={!selectedId}
              onClick={handleGo}
              className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-3 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-60"
            >
              {t('picker.viewRequests')}
              <ArrowRightIcon className="size-4" />
            </button>
          </div>

          <p className="mt-6 border-t border-slate-100 pt-4 text-xs text-slate-400">
            {t('picker.bragaNotePrefix')}{' '}
            <code className="rounded bg-slate-100 px-1 py-0.5 text-slate-500">
              /nutritionists/&lt;id&gt;/requests
            </code>{' '}
            {t('picker.bragaNoteSuffix')}
          </p>
        </div>
      </main>
    </div>
  )
}
