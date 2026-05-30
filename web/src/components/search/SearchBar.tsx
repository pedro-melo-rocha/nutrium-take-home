import { useState, type FormEvent } from 'react'
import { CrosshairIcon, PinIcon, SearchIcon } from '../icons'
import { Spinner } from '../Spinner'

export interface SearchBarProps {
  initialQuery: string
  initialLocation: string
  geoActive: boolean
  geoLoading: boolean
  onSearch: (q: string, location: string) => void
  onUseLocation: () => void
  onClearLocation: () => void
}

// The parent remounts this via `key` when URL-driven params change, so local
// input state always starts from the latest values — no sync effect needed.
export function SearchBar({
  initialQuery,
  initialLocation,
  geoActive,
  geoLoading,
  onSearch,
  onUseLocation,
  onClearLocation,
}: SearchBarProps) {
  const [q, setQ] = useState(initialQuery)
  const [location, setLocation] = useState(initialLocation)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    onSearch(q.trim(), location.trim())
  }

  function handleLocationChange(value: string) {
    setLocation(value)
    if (geoActive) onClearLocation()
  }

  function handleGeoButton() {
    if (geoActive) onClearLocation()
    else onUseLocation()
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex flex-col gap-2 rounded-xl bg-white/15 p-2 backdrop-blur-sm sm:flex-row sm:items-stretch"
    >
      <div className="flex flex-1 items-center gap-2 rounded-lg bg-white px-3.5 py-2.5">
        <SearchIcon className="size-5 shrink-0 text-slate-400" />
        <input
          type="text"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Name, service, online appointment…"
          aria-label="Search by name or service"
          className="w-full bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400"
        />
      </div>

      <div className="flex flex-1 items-center gap-2 rounded-lg bg-white px-3.5 py-2.5 sm:max-w-64">
        <PinIcon className="size-5 shrink-0 text-slate-400" />
        <input
          type="text"
          value={location}
          onChange={(e) => handleLocationChange(e.target.value)}
          placeholder={geoActive ? 'Near me' : 'Location'}
          aria-label="Location"
          disabled={geoActive}
          className="w-full bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400 disabled:text-brand-600"
        />
        <button
          type="button"
          onClick={handleGeoButton}
          title={geoActive ? 'Clear location' : 'Use my location'}
          aria-pressed={geoActive}
          className={`grid size-7 shrink-0 place-items-center rounded-full transition ${
            geoActive
              ? 'bg-brand-500 text-white'
              : 'text-slate-400 hover:bg-slate-100 hover:text-brand-600'
          }`}
        >
          {geoLoading ? (
            <Spinner className="size-4" />
          ) : (
            <CrosshairIcon className="size-4" />
          )}
        </button>
      </div>

      <button
        type="submit"
        className="rounded-lg bg-coral-500 px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-coral-600 active:scale-[0.98]"
      >
        Search
      </button>
    </form>
  )
}
