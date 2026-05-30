export interface Service {
  id: number
  name: string
  price_cents: number
  location: string
  duration_minutes: number
}

export interface NutritionistCard {
  id: number
  name: string
  title: string | null
  license_number: string | null
  photo_url: string | null
  services: Service[]
  /** Present only in geo ("near me") mode. */
  distance_km?: number
}

export interface Pagination {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface SearchResponse {
  location: string | null
  query: string | null
  sorted_by: 'name' | 'distance'
  results: NutritionistCard[]
  pagination: Pagination
}

export type AppointmentStatus = 'pending' | 'accepted' | 'rejected'

export interface AppointmentRequest {
  id: number
  status: AppointmentStatus
  starts_at: string
  ends_at: string
  guest_name: string
  guest_email: string
  created_at: string
  service?: Service
  nutritionist?: { id: number; name: string }
}

export interface QueueResponse {
  nutritionist: { id: number; name: string }
  results: AppointmentRequest[]
}

export interface LookupResponse {
  active: AppointmentRequest | null
}
