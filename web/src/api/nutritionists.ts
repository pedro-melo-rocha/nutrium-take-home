import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { apiFetch } from '../lib/api'
import type { SearchResponse } from '../lib/types'

export interface SearchParams {
  q?: string
  location?: string
  page?: number
  per_page?: number
  lat?: number
  lng?: number
}

function buildQuery(params: SearchParams): string {
  const sp = new URLSearchParams()
  if (params.q) sp.set('q', params.q)
  if (params.location) sp.set('location', params.location)
  if (params.page && params.page > 1) sp.set('page', String(params.page))
  if (params.per_page) sp.set('per_page', String(params.per_page))
  if (params.lat != null && params.lng != null) {
    sp.set('lat', String(params.lat))
    sp.set('lng', String(params.lng))
  }
  const qs = sp.toString()
  return qs ? `?${qs}` : ''
}

export function useNutritionistSearch(params: SearchParams) {
  return useQuery({
    queryKey: ['nutritionists', params],
    queryFn: () =>
      apiFetch<SearchResponse>(`/api/v1/nutritionists${buildQuery(params)}`),
    placeholderData: keepPreviousData,
  })
}
