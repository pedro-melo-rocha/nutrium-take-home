import { createBrowserRouter, Navigate } from 'react-router-dom'
import SearchPage from './pages/SearchPage'
import QueuePage from './pages/QueuePage'
import ProfessionalPickerPage from './pages/ProfessionalPickerPage'

export const router = createBrowserRouter([
  { path: '/', element: <SearchPage /> },
  { path: '/professional', element: <ProfessionalPickerPage /> },
  { path: '/nutritionists/:id/requests', element: <QueuePage /> },
  { path: '*', element: <Navigate to="/" replace /> },
])
