import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useNutritionistSearch, type SearchParams } from '../api/nutritionists'
import { Logo } from '../components/Logo'
import { Spinner } from '../components/Spinner'
import { ArrowRightIcon } from '../components/icons'
import { NutritionistCard } from '../components/search/NutritionistCard'
import { Pagination } from '../components/search/Pagination'
import { SearchBar } from '../components/search/SearchBar'
import { ScheduleModal } from '../components/search/ScheduleModal'
import { useGeolocation } from '../lib/useGeolocation'
import type { NutritionistCard as Nutritionist } from '../lib/types'

export default function SearchPage() {
  const [sp, setSp] = useSearchParams()
  const geo = useGeolocation()
  const [selected, setSelected] = useState<Nutritionist | null>(null)

  const q = sp.get('q') ?? ''
  const location = sp.get('location') ?? ''
  const page = Math.max(1, Number(sp.get('page') ?? '1'))

  const params: SearchParams = geo.coords
    ? { q, page, lat: geo.coords.lat, lng: geo.coords.lng }
    : { q, location, page }

  const { data, isLoading, isError, isFetching } = useNutritionistSearch(params)

  function updateParams(next: Record<string, string>) {
    const merged = new URLSearchParams(sp)
    for (const [k, v] of Object.entries(next)) {
      if (v) merged.set(k, v)
      else merged.delete(k)
    }
    setSp(merged)
  }

  function handleSearch(qv: string, locv: string) {
    geo.clear()
    setSp(
      new URLSearchParams({
        ...(qv && { q: qv }),
        ...(locv && { location: locv }),
      }),
    )
  }

  function handleUseLocation() {
    geo.request()
    updateParams({ page: '' })
  }

  function handleClearLocation() {
    geo.clear()
  }

  return (
    <div className="min-h-screen">
      <header className="bg-linear-to-r from-brand-700 via-brand-600 to-brand-400">
        <div className="mx-auto max-w-5xl px-4 py-4">
          <div className="mb-4 flex items-center justify-between text-white">
            <Logo className="text-white" />
            <Link
              to="/nutritionists/1/requests"
              className="hidden items-center gap-1.5 text-sm font-medium text-white/90 transition hover:text-white sm:inline-flex"
            >
              Are you a nutrition professional?
              <ArrowRightIcon className="size-4" />
            </Link>
          </div>
          <SearchBar
            key={`${q}|${location}|${geo.coords ? 'geo' : 'loc'}`}
            initialQuery={q}
            initialLocation={location}
            geoActive={!!geo.coords}
            geoLoading={geo.loading}
            onSearch={handleSearch}
            onUseLocation={handleUseLocation}
            onClearLocation={handleClearLocation}
          />
          {geo.error && (
            <p className="mt-2 text-sm text-white/90">{geo.error}</p>
          )}
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-6">
        <ResultsHeader
          loading={isLoading}
          fetching={isFetching}
          total={data?.pagination.total_count}
          location={data?.location ?? null}
          sortedBy={data?.sorted_by}
        />

        {isLoading ? (
          <SkeletonList />
        ) : isError ? (
          <EmptyState
            title="Couldn't load nutritionists"
            body="Check that the API is running, then try again."
          />
        ) : data && data.results.length > 0 ? (
          <>
            <div className="flex flex-col gap-4">
              {data.results.map((n) => (
                <NutritionistCard
                  key={n.id}
                  nutritionist={n}
                  onSchedule={setSelected}
                />
              ))}
            </div>
            <div className="mt-8">
              <Pagination
                page={data.pagination.page}
                totalPages={data.pagination.total_pages}
                onChange={(p) => updateParams({ page: String(p) })}
              />
            </div>
          </>
        ) : (
          <EmptyState
            title="No nutritionists found"
            body="Try a different name, service, or location."
          />
        )}
      </main>

      {selected && (
        <ScheduleModal
          nutritionist={selected}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  )
}

function ResultsHeader({
  loading,
  fetching,
  total,
  location,
  sortedBy,
}: {
  loading: boolean
  fetching: boolean
  total?: number
  location: string | null
  sortedBy?: 'name' | 'distance'
}) {
  return (
    <div className="mb-4 flex items-center gap-2">
      <h1 className="text-sm text-slate-500">
        {loading
          ? 'Searching…'
          : sortedBy === 'distance'
            ? `${total} nutritionists · nearest first`
            : `${total} nutritionists${location ? ` in ${location}` : ''}`}
      </h1>
      {fetching && !loading && <Spinner className="size-4 text-brand-500" />}
    </div>
  )
}

function SkeletonList() {
  return (
    <div className="flex flex-col gap-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <div
          key={i}
          className="flex animate-pulse gap-4 rounded-2xl border border-slate-200 bg-white p-5"
        >
          <div className="size-16 shrink-0 rounded-full bg-slate-200" />
          <div className="flex-1 space-y-3 py-1">
            <div className="h-4 w-40 rounded bg-slate-200" />
            <div className="h-3 w-28 rounded bg-slate-200" />
            <div className="h-8 w-full rounded bg-slate-100" />
          </div>
        </div>
      ))}
    </div>
  )
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-300 bg-white py-16 text-center">
      <p className="text-base font-medium text-slate-700">{title}</p>
      <p className="mt-1 text-sm text-slate-500">{body}</p>
    </div>
  )
}
