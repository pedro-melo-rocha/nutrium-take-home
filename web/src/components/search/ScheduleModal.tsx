import {
  useEffect,
  useId,
  useState,
  type FormEvent,
  type ReactNode,
} from 'react'
import { useTranslation } from 'react-i18next'
import { lookupGuest, useCreateAppointment } from '../../api/appointments'
import { ApiError } from '../../lib/api'
import { formatDateTime, formatDuration, formatPrice } from '../../lib/format'
import type { AppointmentRequest, NutritionistCard } from '../../lib/types'
import { AlertIcon, CalendarIcon, CheckIcon, CloseIcon } from '../icons'
import { Spinner } from '../Spinner'

interface Props {
  nutritionist: NutritionistCard
  onClose: () => void
}

function defaultSlot(): string {
  const d = new Date(Date.now() + 60 * 60 * 1000)
  d.setMinutes(0, 0, 0)
  return toLocalInput(d)
}

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours(),
  )}:${pad(d.getMinutes())}`
}

export function ScheduleModal({ nutritionist, onClose }: Props) {
  const { t } = useTranslation()
  const titleId = useId()
  const create = useCreateAppointment()

  const [serviceId, setServiceId] = useState(nutritionist.services[0]?.id ?? 0)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [startsAt, setStartsAt] = useState(defaultSlot)
  const [conflict, setConflict] = useState<AppointmentRequest | null>(null)
  const [checking, setChecking] = useState(false)
  const [confirmed, setConfirmed] = useState(false)

  // Lock body scroll + close on Escape.
  useEffect(() => {
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => {
      document.body.style.overflow = prev
      window.removeEventListener('keydown', onKey)
    }
  }, [onClose])

  function doCreate() {
    create.mutate({
      service_id: serviceId,
      guest_name: name.trim(),
      guest_email: email.trim(),
      starts_at: new Date(startsAt).toISOString(),
    })
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (confirmed) return doCreate()

    setChecking(true)
    try {
      const { active } = await lookupGuest(email.trim())
    
      if (active && active.status === 'pending') {
        setConflict(active)
        return
      }
    } catch {
      // Lookup failed — don't block booking; the backend still enforces the
      // one-pending-per-guest rule on create.
    } finally {
      setChecking(false)
    }
    doCreate()
  }

  const succeeded = create.isSuccess
  const minSlot = toLocalInput(new Date())

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/40 p-0 backdrop-blur-sm sm:items-center sm:p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg rounded-t-2xl bg-white shadow-xl sm:rounded-2xl"
      >
        <header className="flex items-start justify-between gap-4 border-b border-slate-100 p-5">
          <div>
            <h2 id={titleId} className="text-lg font-semibold text-slate-800">
              {succeeded
                ? t('modal.sentTitle')
                : conflict
                  ? t('modal.confirmReplaceTitle')
                  : t('modal.scheduleTitle')}
            </h2>
            <p className="text-sm text-slate-500">
              {t('modal.with', { name: nutritionist.name })}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t('common.close')}
            className="grid size-8 place-items-center rounded-full text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
          >
            <CloseIcon className="size-5" />
          </button>
        </header>

        {succeeded ? (
          <Confirmation onClose={onClose} email={email} />
        ) : conflict ? (
          <ConfirmReplace
            conflict={conflict}
            pending={create.isPending}
            error={
              create.isError
                ? create.error instanceof ApiError
                  ? create.error.message
                  : t('modal.genericError')
                : null
            }
            onBack={() => {
              setConflict(null)
              setConfirmed(false)
            }}
            onConfirm={() => {
              setConfirmed(true)
              doCreate()
            }}
          />
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4 p-5">
            <fieldset className="flex flex-col gap-2">
              <legend className="mb-1 text-sm font-medium text-slate-700">
                {t('modal.service')}
              </legend>
              {nutritionist.services.map((s) => (
                <label
                  key={s.id}
                  className={`flex cursor-pointer items-center gap-3 rounded-lg border px-3 py-2.5 text-sm transition ${
                    serviceId === s.id
                      ? 'border-brand-500 bg-brand-50'
                      : 'border-slate-200 hover:border-slate-300'
                  }`}
                >
                  <input
                    type="radio"
                    name="service"
                    value={s.id}
                    checked={serviceId === s.id}
                    onChange={() => setServiceId(s.id)}
                    className="accent-brand-500"
                  />
                  <span className="font-medium text-slate-700">{s.name}</span>
                  <span className="text-slate-400">
                    {s.location} · {formatDuration(s.duration_minutes)}
                  </span>
                  <span className="ml-auto font-semibold text-slate-700">
                    {formatPrice(s.price_cents)}
                  </span>
                </label>
              ))}
            </fieldset>

            <Field label={t('modal.name')}>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder={t('modal.namePlaceholder')}
                className="input"
              />
            </Field>

            <Field label={t('modal.email')}>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={t('modal.emailPlaceholder')}
                className="input"
              />
            </Field>

            <Field label={t('modal.dateTime')}>
              <div className="relative">
                <CalendarIcon className="pointer-events-none absolute left-3 top-1/2 size-5 -translate-y-1/2 text-slate-400" />
                <input
                  type="datetime-local"
                  required
                  min={minSlot}
                  value={startsAt}
                  onChange={(e) => setStartsAt(e.target.value)}
                  className="input pl-10"
                />
              </div>
            </Field>

            <p className="text-xs text-slate-400">
              {t('modal.supersedeNote')}
            </p>

            {create.isError && (
              <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
                {create.error instanceof ApiError
                  ? create.error.message
                  : t('modal.genericError')}
              </p>
            )}

            <button
              type="submit"
              disabled={create.isPending || checking}
              className="mt-1 inline-flex items-center justify-center gap-2 rounded-lg bg-coral-500 px-4 py-3 text-sm font-semibold text-white transition hover:bg-coral-600 disabled:opacity-60"
            >
              {(create.isPending || checking) && <Spinner className="size-4" />}
              {t('modal.submit')}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}

function Field({
  label,
  children,
}: {
  label: string
  children: ReactNode
}) {
  return (
    <label className="flex flex-col gap-1.5 text-sm font-medium text-slate-700">
      {label}
      {children}
    </label>
  )
}

function ConfirmReplace({
  conflict,
  pending,
  error,
  onBack,
  onConfirm,
}: {
  conflict: AppointmentRequest
  pending: boolean
  error: string | null
  onBack: () => void
  onConfirm: () => void
}) {
  const { t } = useTranslation()
  return (
    <div className="flex flex-col gap-4 p-5">
      <div className="flex gap-3">
        <div className="grid size-10 shrink-0 place-items-center rounded-full bg-amber-100 text-amber-600">
          <AlertIcon className="size-5" />
        </div>
        <p className="text-sm text-slate-600">
          {t('modal.confirmReplaceBody', {
            nutritionist: conflict.nutritionist?.name ?? '',
            service: conflict.service?.name ?? '',
            when: formatDateTime(conflict.starts_at),
          })}
        </p>
      </div>

      {error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
          {error}
        </p>
      )}

      <div className="flex gap-2">
        <button
          type="button"
          onClick={onBack}
          disabled={pending}
          className="flex-1 rounded-lg border border-slate-300 px-4 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 disabled:opacity-60"
        >
          {t('modal.confirmReplaceBack')}
        </button>
        <button
          type="button"
          onClick={onConfirm}
          disabled={pending}
          className="inline-flex flex-1 items-center justify-center gap-2 rounded-lg bg-coral-500 px-4 py-3 text-sm font-semibold text-white transition hover:bg-coral-600 disabled:opacity-60"
        >
          {pending && <Spinner className="size-4" />}
          {t('modal.confirmReplaceCta')}
        </button>
      </div>
    </div>
  )
}

function Confirmation({
  email,
  onClose,
}: {
  email: string
  onClose: () => void
}) {
  const { t } = useTranslation()
  return (
    <div className="flex flex-col items-center gap-3 p-8 text-center">
      <div className="grid size-14 place-items-center rounded-full bg-brand-100 text-brand-600">
        <CheckIcon className="size-7" />
      </div>
      <p className="text-base font-medium text-slate-800">
        {t('modal.confirmationPending')}
      </p>
      <p className="max-w-sm text-sm text-slate-500">
        {t('modal.confirmationEmailNote', { email })}
      </p>
      <button
        type="button"
        onClick={onClose}
        className="mt-2 rounded-lg bg-brand-500 px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-600"
      >
        {t('common.done')}
      </button>
    </div>
  )
}
