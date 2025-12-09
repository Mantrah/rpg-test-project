import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { brokerApi } from '../services/api'
import Loading from '../components/Loading'
import ErrorMessage from '../components/ErrorMessage'
import ButtonSpinner from '../components/ButtonSpinner'

const BrokerList = () => {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [statusFilter, setStatusFilter] = useState('ACT')
  const [deletingId, setDeletingId] = useState(null)

  const { data, isLoading, error } = useQuery({
    queryKey: ['brokers', statusFilter],
    queryFn: () => brokerApi.getAll(statusFilter),
  })

  const deleteMutation = useMutation({
    mutationFn: (id) => brokerApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['brokers'] })
      setDeletingId(null)
    },
    onError: () => {
      setDeletingId(null)
    }
  })

  const handleDelete = (broker) => {
    if (window.confirm(`Supprimer le courtier "${broker.COMPANY_NAME}" ?`)) {
      setDeletingId(broker.BROKER_ID)
      deleteMutation.mutate(broker.BROKER_ID)
    }
  }

  const handleCreateContract = (broker) => {
    navigate('/contracts/create', { state: { broker } })
  }

  if (isLoading) return <Loading message="Chargement des courtiers..." />
  if (error) return <ErrorMessage message={error.message} code={error.code} />

  const brokers = data?.data || []

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Courtiers</h1>
          <p className="mt-2 text-gray-600">
            Liste des courtiers partenaires DAS Belgium
          </p>
        </div>
        <div className="flex items-end space-x-4">
          <div>
            <label className="label">Statut</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input-field"
            >
              <option value="">Tous</option>
              <option value="ACT">Actif</option>
              <option value="SUS">Suspendu</option>
            </select>
          </div>
          <button
            onClick={() => navigate('/brokers/create')}
            className="btn-success"
          >
            + Nouveau Courtier
          </button>
        </div>
      </div>

      {/* Info Banner */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p className="text-blue-800 text-sm">
          <strong>Modèle DAS Belgium:</strong> Distribution 100% via courtiers d'assurance.
          Sélectionnez un courtier pour créer un nouveau contrat.
        </p>
      </div>

      {/* Brokers Table */}
      <div className="card overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Code
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Société
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Localisation
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Contact
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Statut
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {brokers.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                    Aucun courtier trouvé
                  </td>
                </tr>
              ) : (
                brokers.map((broker) => (
                  <tr key={broker.BROKER_ID} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-medium text-das-blue">
                        {broker.BROKER_CODE}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">
                        {broker.COMPANY_NAME}
                      </div>
                      <div className="text-sm text-gray-500">
                        FSMA: {broker.FSMA_NUMBER}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {broker.CITY} ({broker.POSTAL_CODE})
                      </div>
                      <div className="text-sm text-gray-500">
                        {broker.COUNTRY_CODE}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {broker.CONTACT_NAME}
                      </div>
                      <div className="text-sm text-gray-500">
                        📞 {broker.PHONE}
                      </div>
                      <div className="text-sm text-gray-500">
                        ✉️ {broker.EMAIL}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {broker.STATUS === 'ACT' ? (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          Actif
                        </span>
                      ) : (
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                          Suspendu
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                      {broker.STATUS === 'ACT' && (
                        <button
                          onClick={() => handleCreateContract(broker)}
                          className="btn-primary text-sm"
                        >
                          Créer Contrat
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(broker)}
                        disabled={deletingId === broker.BROKER_ID}
                        className="px-3 py-1 text-sm text-red-600 hover:text-red-800 hover:bg-red-50 rounded disabled:opacity-50 flex items-center gap-1"
                      >
                        {deletingId === broker.BROKER_ID && <ButtonSpinner className="text-red-600" />}
                        {deletingId === broker.BROKER_ID ? 'Suppression...' : 'Supprimer'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Stats Footer */}
      {brokers.length > 0 && (
        <div className="text-sm text-gray-600">
          Total: {brokers.length} courtier(s) affiché(s)
        </div>
      )}
    </div>
  )
}

export default BrokerList
